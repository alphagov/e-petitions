class SponsorsController < SignaturesController
  skip_before_filter :redirect_to_petition_page_if_rejected
  skip_before_filter :redirect_to_petition_page_if_closed
  skip_before_filter :redirect_to_petition_page_if_closed_for_signing

  before_action :redirect_to_petition_page_if_moderated, except: [:thank_you, :signed]
  before_action :redirect_to_moderation_info_page_if_sponsored, except: [:thank_you, :signed]
  before_action :validate_creator, only: [:new]

  def verify
    unless @signature.validated?
      @signature.validate!
    end

    redirect_to signed_sponsor_url(@signature, token: @signature.perishable_token)
  end

  private

  def retrieve_petition
    @petition = Petition.not_hidden.find(petition_id)

    if @petition.flagged? || @petition.stopped?
      raise ActiveRecord::RecordNotFound, "Unable to find Petition with id: #{petition_id}"
    end

    unless @petition.sponsor_token == token_param
      raise ActiveRecord::RecordNotFound, "Unable to find Petition with sponsor token: #{token_param.inspect}"
    end
  end

  def retrieve_signature
    @signature = Signature.sponsors.find(signature_id)
    @petition = @signature.petition

    if @petition.flagged? || @petition.hidden? || @petition.stopped?
      raise ActiveRecord::RecordNotFound, "Unable to find Signature with id: #{signature_id}"
    end

    if @signature.invalidated? || @signature.fraudulent?
      raise ActiveRecord::RecordNotFound, "Unable to find Signature with id: #{signature_id}"
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

  def validate_creator
    @petition.validate_creator!
  end
end
