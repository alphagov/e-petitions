class SignaturesController < ApplicationController
  include ManagingMoveParameter

  before_action :retrieve_petition, only: [:new, :create, :thank_you]
  before_action :retrieve_signature, only: [:verify, :unsubscribe, :signed]
  before_action :verify_token, only: [:verify, :signed]
  before_action :verify_unsubscribe_token, only: [:unsubscribe]
  before_action :redirect_to_petition_page, if: :petition_closed?, only: [:new, :create, :verify]
  before_action :redirect_to_verify_page, unless: :signature_validated?, only: [:signed]
  before_action :do_not_cache

  respond_to :html

  def new
    assign_stage
    @stage_manager = Staged::PetitionSigner.manage(signature_params_for_new, request, @petition, params[:stage], params[:move])
    respond_with @stage_manager.stage_object
  end

  def create
    matching_signatures = find_existing_pending_signatures

    if matching_signatures.any?
      handle_existing_signatures(matching_signatures, @petition)
    else
      handle_new_signature(@petition)
    end
  end

  def signed
    if @signature.seen_signed_confirmation_page?
      redirect_to petition_url @signature.petition
    else
      @signature.mark_seen_signed_confirmation_page!
      @petition = @signature.petition
      respond_to do |format|
        format.html
      end
    end
  end

  def verify
    if @signature.sponsor?
      validate_sponsor
    else
      validate_signature
    end
  end

  def unsubscribe
    @signature.unsubscribe!(token_param)
    respond_to do |format|
      format.html
    end
  end

  def thank_you
    respond_to do |format|
      format.html
    end
  end

  private

  def token_param
    @token_param ||= (params[:token] || params[:legacy_token]).to_s
  end

  def verify_token
    unless @signature.perishable_token == token_param
      raise ActiveRecord::RecordNotFound, "Unable to find Signature with token: token_param.inspect}"
    end
  end

  def verify_unsubscribe_token
    unless @signature.unsubscribe_token == token_param
      raise ActiveRecord::RecordNotFound, "Unable to find Signature with unsubscribe token: #{token_param.inspect}"
    end
  end

  def retrieve_petition
    @petition = Petition.visible.find(params[:petition_id])
  end

  def retrieve_signature
    @signature = Signature.find(params[:id])
    @petition = @signature.petition

    if @signature.invalidated? || @signature.fraudulent?
      raise ActiveRecord::RecordNotFound, "Unable to find Signature with id: #{params[:id]}"
    end
  end

  def redirect_to_petition_page
    redirect_to petition_url(@petition)
  end

  def redirect_to_verify_page
    redirect_to verify_signature_url(@signature, token: @signature.perishable_token)
  end

  def petition_closed?
    @petition && @petition.closed?
  end

  def signature_validated?
    @signature && @signature.validated?
  end

  def send_email_to_petition_signer(signature)
    EmailConfirmationForSignerEmailJob.perform_later(signature)
  end

  def assign_stage
    return if Staged::PetitionSigner.stages.include? params[:stage]
    params[:stage] = 'signer'
  end

  def signature_params_for_new
    {location_code: 'GB'}
  end

  def signature_params_for_create
    @_signature_params_for_create ||=
      params.
        require(:signature).
        permit(:name, :email, :email_confirmation,
               :postcode, :location_code, :uk_citizenship)
  end

  def find_existing_pending_signatures
    @signature = Signature.new(signature_params_for_create)
    @signature.email.strip!
    @signature.petition = @petition
    Signature.pending.matching(@signature)
  end

  def handle_existing_signatures(signatures, petition)
    signatures.each { |sig| send_email_to_petition_signer(sig) }
    redirect_to thank_you_petition_signatures_url(petition)
  end

  def handle_new_signature(petition)
    assign_move
    assign_stage
    @stage_manager = Staged::PetitionSigner.manage(signature_params_for_create, request, petition, params[:stage], params[:move])
    if @stage_manager.create_signature
      @stage_manager.signature.store_constituency_id
      send_email_to_petition_signer(@stage_manager.signature)
      respond_with @stage_manager.stage_object, :location => thank_you_petition_signatures_url(petition)
    else
      respond_to do |format|
        format.html { render :new }
      end
    end
  rescue ActiveRecord::RecordNotUnique => e
    redirect_to thank_you_petition_signatures_url(petition)
  end

  def validate_sponsor
    if @signature.validated?
      flash[:notice] = "You've already supported this petition."
      redirect_to sponsored_petition_sponsor_url(@signature.petition, token: @signature.petition.sponsor_token)
    else
      @signature.validate!

      if @signature.petition.open?
        redirect_to signed_signature_url(@signature, token: @signature.perishable_token)
      else
        redirect_to sponsored_petition_sponsor_url(@signature.petition, token: @signature.petition.sponsor_token)
      end
    end
  end

  def validate_signature
    if @signature.validated?
      flash[:notice] = "You've already signed this petition"
    else
      @signature.validate!
    end
    redirect_to signed_signature_url(@signature, token: @signature.perishable_token)
  end
end

