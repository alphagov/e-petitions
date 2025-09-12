class SponsorCreator < SignatureCreator
  def scope
    @petition.sponsors
  end

  def to_partial_path
    "sponsors/create/#{stage}_stage"
  end

  private

  def send_email_to_petition_signer
    unless @signature.email_threshold_reached?
      if @signature.pending?
        PetitionAndEmailConfirmationForSponsorEmailJob.perform_later(@signature)
      else
        EmailDuplicateSignaturesEmailJob.perform_later(@signature)
      end
    end
  end
end
