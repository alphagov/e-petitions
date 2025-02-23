class PetitionAndEmailConfirmationForSponsorEmailJob < EmailJob
  self.mailer = PetitionMailer
  self.email = :petition_and_email_confirmation_for_sponsor

  include RateLimiting
end
