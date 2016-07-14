class EmailConfirmationForSignerEmailJob < EmailJob
  self.mailer = PetitionMailer
  self.email = :email_confirmation_for_signer

  rescue_from(ActiveJob::DeserializationError) do |exception|
    Appsignal.send_exception exception
  end

  def perform(signature)
    if rate_limit.exceeded?(signature)
      signature.fraudulent!
    else
      mailer.send(email, signature).deliver_now
    end
  end

  private

  def rate_limit
    @rate_limit ||= RateLimit.first_or_create!
  end
end
