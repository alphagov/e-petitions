class SponsorSignedEmailOnThresholdEmailJob < EmailJob
  self.mailer = SponsorMailer
  self.email = :sponsor_signed_email_on_threshold
end
