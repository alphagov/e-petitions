class SignaturesController < ApplicationController
  include ManagingMoveParameter

  before_filter :retrieve_petition, :only => [:new, :create, :thank_you]
  before_filter :retrieve_signature, :only => [:verify, :unsubscribe, :signed]
  before_action :do_not_cache

  respond_to :html

  def new
    assign_stage
    @stage_manager = Staged::PetitionSigner.manage(signature_params_for_new, @petition, params[:stage], params[:move])
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
    verify_token

    if @signature.validated?
      @petition = @signature.petition
    else
      redirect_to(verify_signature_url(@signature, @signature.perishable_token))
    end
  end

  def verify
    verify_token

    if @signature.sponsor?
      validate_sponsor
    else
      validate_signature
    end
  end

  def unsubscribe
    if @signature.unsubscribe_token != params[:unsubscribe_token]
      render 'signatures/unsubscribe/failed_to_unsubscribe'
    elsif @signature.unsubscribed?
      render 'signatures/unsubscribe/already_unsubscribed'
    else
      @signature.unsubscribe!
      render 'signatures/unsubscribe/successfully_unsubscribed'
    end
  end

  private

  def verify_token
    raise ActiveRecord::RecordNotFound unless @signature.perishable_token == params[:token]
  end

  def retrieve_petition
    @petition = Petition.visible.find(params[:petition_id])
  end

  def retrieve_signature
    @signature = Signature.find(params[:id])
  end

  def send_email_to_petition_signer(signature)
    PetitionMailer.email_confirmation_for_signer(signature).deliver_later
  end

  def assign_stage
    return if Staged::PetitionSigner.stages.include? params[:stage]
    params[:stage] = 'signer'
  end

  def signature_params_for_new
    {country: 'United Kingdom'}
  end

  def signature_params_for_create
    @_signature_params_for_create ||=
      params.
        require(:signature).
        permit(:name, :email, :email_confirmation,
               :postcode, :country, :uk_citizenship)
  end

  def send_sponsor_support_notification_email_to_petition_owner(petition, signature)
    petition.notify_creator_about_sponsor_support(petition.sponsors.for(signature)) unless petition.in_moderation?
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
    @stage_manager = Staged::PetitionSigner.manage(signature_params_for_create, petition, params[:stage], params[:move])
    if @stage_manager.create_signature
      @stage_manager.signature.store_constituency_id
      send_email_to_petition_signer(@stage_manager.signature)
      respond_with @stage_manager.stage_object, :location => thank_you_petition_signatures_url(petition)
    else
      render :new
    end
  end

  def validate_sponsor
    if @signature.validated?
      flash[:notice] = "Thank you. You have already sponsored this petition."
    else
      @signature.validate!
      send_sponsor_support_notification_email_to_petition_owner(@signature.petition, @signature)
      @signature.petition.update_state_after_new_validated_sponsor!
    end
    redirect_to sponsored_petition_sponsor_url(@signature.petition, token: @signature.petition.sponsor_token)
  end

  def validate_signature
    if @signature.validated?
      flash[:notice] = "Thank you. Your signature has already been added to the petition."
    else
      @signature.validate!
    end
    redirect_to signed_signature_url(@signature, token: @signature.perishable_token)
  end
end

