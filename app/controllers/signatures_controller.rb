class SignaturesController < PublicController
  before_action :retrieve_petition, only: [:new, :confirm, :create, :thank_you]
  before_action :retrieve_signature, only: [:verify, :unsubscribe, :signed]

  # Verify petition is in a valid state before processing signature
  before_action :redirect_to_petition_page_if_rejected, only: [:new, :confirm, :create, :thank_you, :verify, :signed]
  before_action :redirect_to_petition_page_if_closed, only: [:new, :confirm, :create, :thank_you]
  before_action :redirect_to_petition_page_if_closed_for_signing, only: [:verify, :signed]
  before_action :redirect_to_petition_page_if_paused, only: [:new, :confirm, :create, :thank_you, :verify, :signed]

  before_action :build_signature, only: [:new, :confirm, :create]
  before_action :expire_signed_tokens, only: [:verify]
  before_action :verify_token, only: [:verify]
  before_action :verify_signed_token, only: [:signed]
  before_action :verify_unsubscribe_token, only: [:unsubscribe]

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
      send_email_to_petition_signer
      redirect_to thank_you_url
    end
  end

  def signed
    unless @signature.seen_signed_confirmation_page?
      @signature.mark_seen_signed_confirmation_page!
    end

    store_signed_tokens_in_cookie

    respond_to do |format|
      format.html
    end
  end

  def verify
    unless @signature.validated?
      @signature.validate!(request: request)
    end

    store_signed_tokens_in_cookie(signed_token_hash)
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
  rescue ArgumentError => e
    raise ActionController::BadRequest, "Invalid petition id: #{params[:petition_id]}"
  end

  def signature_id
    @signature_id ||= Integer(params[:id])
  rescue ArgumentError => e
    raise ActionController::BadRequest, "Invalid signature id: #{params[:id]}"
  end

  def token_param
    @token_param ||= params[:token].to_s.encode('utf-8', invalid: :replace)
  end

  def load_signed_tokens
    JSON.parse(cookies.encrypted[:signed_tokens].to_s) || {}
  rescue JSON::ParserError
    {}
  end

  def dump_signed_tokens(extra_tokens = {})
    signed_tokens.merge(extra_tokens).to_json
  end

  def signed_tokens
    @signed_tokens ||= load_signed_tokens
  end

  def fetch_signed_token
    signed_tokens.delete(signature_id.to_s)
  end

  def signed_token_hash
    { signature_id.to_s => @signature.signed_token }
  end

  def expire_signed_tokens
    signed_tokens.delete_if { |id, token| Signature.validated?(id) }
  end

  def store_signed_tokens_in_cookie(extra_tokens = {})
    cookies.encrypted[:signed_tokens] = { value: dump_signed_tokens(extra_tokens), httponly: true, same_site: :lax }
  end

  def verify_token
    unless @signature.perishable_token == token_param
      redirect_to token_failure_url
    end
  end

  def verify_signed_token
    unless @signature.signed_token == fetch_signed_token
      redirect_to token_failure_url
    end
  end

  def verify_unsubscribe_token
    unless @signature.unsubscribe_token == token_param
      redirect_to token_failure_url
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

  def token_failure_url
    if @petition.visible?
      petition_url(@petition)
    elsif @petition.collecting_sponsors?
      gathering_support_petition_url(@petition)
    else
      moderation_info_petition_url(@petition)
    end
  end

  def redirect_to_petition_page_if_rejected
    if @petition.rejected?
      redirect_to petition_url(@petition), notice: :cant_sign_rejected
    end
  end

  def redirect_to_petition_page_if_closed
    if @petition.closed?
      redirect_to petition_url(@petition), notice: :cant_sign_closed
    end
  end

  def redirect_to_petition_page_if_closed_for_signing
    if @petition.closed_for_signing?
      redirect_to petition_url(@petition), notice: :cant_sign_closed
    end
  end

  def redirect_to_petition_page_if_paused
    if Site.signature_collection_disabled?
      redirect_to petition_url(@petition), notice: :cant_sign_paused
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
    { location_code: "GB" }
  end

  def signature_params
    params.require(:signature).permit(*signature_attributes)
  end

  def signature_params_for_create
    signature_params.merge(ip_address: request.remote_ip)
  end

  def signature_attributes
    %i[name email email_confirmation postcode location_code uk_citizenship notify_by_email autocorrect_domain]
  end
end
