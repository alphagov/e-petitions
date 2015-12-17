class EmailConfirmationForSignerEmailJob < EmailJob
  self.mailer = PetitionMailer
  self.email = :email_confirmation_for_signer
end
