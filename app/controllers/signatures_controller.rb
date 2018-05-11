class SignaturesController < ApplicationController
  before_action :retrieve_petition, only: [:new, :confirm, :create, :thank_you]
  before_action :retrieve_signature, only: [:verify, :unsubscribe, :signed]
  before_action :verify_token, only: [:verify, :signed]
  before_action :verify_unsubscribe_token, only: [:unsubscribe]
  before_action :redirect_to_petition_page_if_rejected, only: [:new, :confirm, :create, :thank_you, :verify, :signed]
  before_action :redirect_to_petition_page_if_closed, only: [:new, :confirm, :create, :thank_you]
  before_action :redirect_to_petition_page_if_closed_for_signing, only: [:verify, :signed]
  before_action :redirect_to_verify_page, unless: :signature_validated?, only: [:signed]
  before_action :do_not_cache

  rescue_from ActiveRecord::RecordNotUnique do |exception|
    @signature = @signature.find_duplicate!
    send_email_to_petition_signer

    redirect_to thank_you_url
  end

  rescue_from ActiveRecord::RecordInvalid do |exception|
    respond_to do |format|
      format.html { render :new }
    end
  end

  def new
    @signature = build_signature(signature_params_for_new)

    respond_to do |format|
      format.html
    end
  end

  def confirm
    @signature = build_signature(signature_params_for_create)

    respond_to do |format|
      format.html { render(@signature.valid? ? :confirm : :new) }
    end
  end

  def create
    @signature = build_signature(signature_params_for_create)

    if @signature.save!
      send_email_to_petition_signer
      redirect_to thank_you_url
    end
  end

  def signed
    if @signature.seen_signed_confirmation_page?
      redirect_to petition_url(@petition)
    else
      @signature.mark_seen_signed_confirmation_page!

      respond_to do |format|
        format.html
      end
    end
  end

  def verify
    if @signature.validated?
      flash[:notice] = "You’ve already signed this petition"
    else
      @signature.validate!
    end

    redirect_to signed_signature_url(@signature, token: @signature.perishable_token)
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

  def petition_id
    @petition_id ||= Integer(params[:petition_id])
  end

  def signature_id
    @signature_id ||= Integer(params[:id])
  end

  def token_param
    @token_param ||= params[:token].to_s.encode('utf-8', invalid: :replace)
  end

  def verify_token
    unless @signature.perishable_token == token_param
      raise ActiveRecord::RecordNotFound, "Unable to find Signature with token: #{token_param.inspect}"
    end
  end

  def verify_unsubscribe_token
    unless @signature.unsubscribe_token == token_param
      raise ActiveRecord::RecordNotFound, "Unable to find Signature with unsubscribe token: #{token_param.inspect}"
    end
  end

  def retrieve_petition
    @petition = Petition.visible.find(petition_id)
  end

  def retrieve_signature
    @signature = Signature.find(signature_id)
    @petition = @signature.petition

    unless @petition.visible?
      raise ActiveRecord::RecordNotFound, "Unable to find Signature with id: #{signature_id}"
    end

    if @signature.invalidated? || @signature.fraudulent?
      raise ActiveRecord::RecordNotFound, "Unable to find Signature with id: #{signature_id}"
    end
  end

  def build_signature(attributes)
    @petition.signatures.build(attributes) { |s| s.ip_address = request.remote_ip }
  end

  def thank_you_url
    thank_you_petition_signatures_url(@petition)
  end

  def verify_url
    verify_signature_url(@signature, token: @signature.perishable_token)
  end

  def redirect_to_petition_page_if_rejected
    if @petition.rejected?
      redirect_to petition_url(@petition), notice: "Sorry, you can't sign petitions that have been rejected"
    end
  end

  def redirect_to_petition_page_if_closed
    if @petition.closed?
      redirect_to petition_url(@petition), notice: "Sorry, you can't sign petitions that have been closed"
    end
  end

  def redirect_to_petition_page_if_closed_for_signing
    if @petition.closed_for_signing?
      redirect_to petition_url(@petition), notice: "Sorry, you can't sign petitions that have been closed"
    end
  end

  def redirect_to_verify_page
    redirect_to verify_url
  end

  def signature_validated?
    @signature.validated?
  end

  def send_email_to_petition_signer
    unless @signature.email_threshold_reached?
      if @signature.pending?
        EmailConfirmationForSignerEmailJob.perform_later(@signature)
      else
        EmailDuplicateSignaturesEmailJob.perform_later(@signature)
      end
    end
  end

  def signature_params_for_new
    { location_code: "GB" }
  end

  def signature_params
    params.require(:signature).permit(*signature_attributes)
  end

  def signature_params_for_create
    signature_params.merge(ip_address: request.remote_ip)
  end

  def signature_attributes
    %i[name email email_confirmation postcode location_code uk_citizenship notify_by_email]
  end
end
