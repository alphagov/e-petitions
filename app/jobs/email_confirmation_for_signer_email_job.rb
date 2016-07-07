class EmailConfirmationForSignerEmailJob < EmailJob
  self.mailer = PetitionMailer
  self.email = :email_confirmation_for_signer

  rescue_from(ActiveJob::DeserializationError) do |exception|
    Appsignal.send_exception exception
  end
end
