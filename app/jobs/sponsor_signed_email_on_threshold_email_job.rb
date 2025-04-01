class SponsorSignedEmailOnThresholdEmailJob < EmailJob
  self.mailer = SponsorMailer

  def perform(signature)
    if signature.validated?
      super
    end
  end

  def email
    if Site.moderation_delay?
      :sponsor_signed_email_on_threshold_with_delay
    else
      :sponsor_signed_email_on_threshold
    end
  end
end
