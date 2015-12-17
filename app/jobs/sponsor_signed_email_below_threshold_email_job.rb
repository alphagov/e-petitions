class SponsorSignedEmailBelowThresholdEmailJob < EmailJob
  self.mailer = SponsorMailer
  self.email = :sponsor_signed_email_below_threshold
end
