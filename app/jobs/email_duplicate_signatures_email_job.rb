class EmailDuplicateSignaturesEmailJob < EmailJob
  self.mailer = PetitionMailer
  self.email = :email_duplicate_signatures

  rescue_from(ActiveJob::DeserializationError) do |exception|
    Appsignal.send_exception exception
  end

  def perform(signature)
    mailer.send(email, signature).deliver_now
    Signature.increment_counter(:email_count, signature.id)
  end
end
