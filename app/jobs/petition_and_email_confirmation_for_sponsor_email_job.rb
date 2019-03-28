class PetitionAndEmailConfirmationForSponsorEmailJob < EmailJob
  self.mailer = SponsorMailer
  self.email = :petition_and_email_confirmation_for_sponsor

  include RateLimiting
end
