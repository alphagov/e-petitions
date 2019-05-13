class SignaturesController < ApplicationController
  include FormTracking

  before_action :retrieve_petition, only: [:new, :confirm, :create, :thank_you]
  before_action :retrieve_signature, only: [:verify, :unsubscribe, :signed]
  before_action :build_signature, only: [:new, :confirm, :create]
  before_action :expire_form_requests, only: [:new]
  before_action :expire_signed_tokens, only: [:verify]
  before_action :verify_token, only: [:verify]
  before_action :verify_signed_token, only: [:signed]
  before_action :verify_unsubscribe_token, only: [:unsubscribe]
  before_action :redirect_to_petition_page_if_rejected, only: [:new, :confirm, :create, :thank_you, :verify, :signed]
  before_action :redirect_to_petition_page_if_closed, only: [:new, :confirm, :create, :thank_you]
  before_action :redirect_to_petition_page_if_closed_for_signing, only: [:verify, :signed]
  before_action :do_not_cache

  rescue_from ActiveRecord::RecordNotUnique do |exception|
    @signature = @signature.find_duplicate!

    delete_form_request
    send_email_to_petition_signer

    redirect_to thank_you_url
  end

  rescue_from ActiveRecord::RecordInvalid do |exception|
    respond_to do |format|
      format.html { render :new }
    end
  end

  def new
    respond_to do |format|
      format.html
    end
  end

  def confirm
    respond_to do |format|
      format.html { render(@signature.valid? ? :confirm : :new) }
    end
  end

  def create
    if @signature.save!
      delete_form_request
      send_email_to_petition_signer

      redirect_to thank_you_url
    end
  end

  def signed
    unless @signature.seen_signed_confirmation_page?
      @signature.mark_seen_signed_confirmation_page!
    end

    respond_to do |format|
      format.html
    end
  end

  def verify
    unless @signature.validated?
      @signature.validate!(request: request)
    end

    store_signed_token_in_session
    redirect_to signed_signature_url(@signature)
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

  def expire_form_requests
    expired_form_requests.each do |id, token|
      cookies.delete(token)
      form_requests.delete(id)
    end
  end

  def expired_form_requests
    form_requests.each_with_object([]) do |(id, hash), expired|
      expired << [id, hash["form_token"]] if form_request_expired?(hash, form_request_max_age)
    end
  end

  def form_request_timestamps
    timestamps = form_requests.map { |_, r| r["form_requested_at"].in_time_zone }
  end

  def last_form_request_timestamp
    form_request_timestamps.sort[-10]
  end

  def form_request_max_age
    [last_form_request_timestamp, 1.day.ago].compact.max
  end

  def form_request_expired?(hash, max_age = 1.day.ago)
    hash["form_requested_at"].in_time_zone < max_age
  end

  def delete_form_request
    cookies.delete(form_token)
    form_requests.delete(form_request_id)
  end

  def signed_tokens
    @signed_tokens = session[:signed_tokens] || {}
  end

  def session_signed_token
    signed_tokens.delete(signature_id.to_s)
  end

  def signed_token_hash
    { signature_id.to_s => @signature.signed_token }
  end

  def expire_signed_tokens
    signed_tokens.delete_if { |id, token| Signature.validated?(id) }
  end

  def store_signed_token_in_session
    session[:signed_tokens] = signed_tokens.merge(signed_token_hash)
  end

  def verify_token
    unless @signature.perishable_token == token_param
      raise ActiveRecord::RecordNotFound, "Unable to find Signature with token: #{token_param.inspect}"
    end
  end

  def verify_signed_token
    unless @signature.signed_token == session_signed_token
      redirect_to signed_token_failure_url
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
  end

  def build_signature
    if action_name == "new"
      @signature = @petition.signatures.build(signature_params_for_new)
    else
      @signature = @petition.signatures.build(signature_params_for_create)
    end
  end

  def thank_you_url
    thank_you_petition_signatures_url(@petition)
  end

  def signed_token_failure_url
    petition_url(@petition)
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
    {
      location_code: "GB",
      form_token: form_token,
      form_requested_at: form_requested_at
    }
  end

  def signature_params
    params.require(:signature).permit(*signature_attributes)
  end

  def signature_params_for_create
    signature_params.merge(
      ip_address: request.remote_ip,
      form_token: form_token,
      form_requested_at: form_requested_at,
      image_loaded_at: image_loaded_at
    )
  end

  def signature_attributes
    %i[name email email_confirmation postcode location_code uk_citizenship notify_by_email]
  end
end
