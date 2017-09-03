class SponsorsController < SignaturesController
  skip_before_filter :redirect_to_petition_page_if_rejected
  skip_before_filter :redirect_to_petition_page_if_closed
  skip_before_filter :redirect_to_petition_page_if_closed_for_signing

  before_action :redirect_to_petition_page_if_moderated, except: [:thank_you, :signed]
  before_action :redirect_to_moderation_info_page_if_sponsored, except: [:thank_you, :signed]
  before_action :validate_creator_signature, only: [:new]

  def verify
    if @signature.validated?
      flash[:notice] = "You’ve already supported this petition"
    else
      @signature.validate!
    end

    redirect_to signed_sponsor_url(@signature, token: @signature.perishable_token)
  end

  def signed
    unless @signature.seen_signed_confirmation_page?
      @signature.mark_seen_signed_confirmation_page!
    end

    respond_to do |format|
      format.html
    end
  end

  private

  def retrieve_petition
    @petition = Petition.not_hidden.find_by!(sponsor_token_and_id)

    if @petition.flagged? || @petition.stopped?
      raise ActiveRecord::RecordNotFound, "Unable to find Petition with id: #{params[:petition_id]}"
    end
  end

  def sponsor_token_and_id
    { sponsor_token: params[:token].to_s, id: params[:petition_id].to_i }
  end

  def retrieve_signature
    @signature = Signature.sponsors.find(params[:id])
    @petition = @signature.petition

    if @petition.flagged? || @petition.hidden? || @petition.stopped?
      raise ActiveRecord::RecordNotFound, "Unable to find Signature with id: #{params[:id]}"
    end

    if @signature.invalidated? || @signature.fraudulent?
      raise ActiveRecord::RecordNotFound, "Unable to find Signature with id: #{params[:id]}"
    end
  end

  def build_signature(attributes)
    @petition.sponsors.build(attributes) { |s| s.ip_address = request.remote_ip }
  end

  def send_email_to_petition_signer
    unless @signature.email_threshold_reached?
      if @signature.pending?
        PetitionAndEmailConfirmationForSponsorEmailJob.perform_later(@signature)
      else
        EmailDuplicateSignaturesEmailJob.perform_later(@signature)
      end
    end
  end

  def thank_you_url
    thank_you_petition_sponsors_url(@petition, token: @petition.sponsor_token)
  end

  def verify_url
    verify_sponsor_url(@signature, token: @signature.perishable_token)
  end

  def redirect_to_petition_page_if_moderated
    if @petition.moderated?
      redirect_to petition_url(@petition)
    end
  end

  def redirect_to_moderation_info_page_if_sponsored
    if @petition.has_maximum_sponsors?
      redirect_to moderation_info_petition_url(@petition)
    end
  end

  def validate_creator_signature
    @petition.validate_creator_signature!
  end
end
