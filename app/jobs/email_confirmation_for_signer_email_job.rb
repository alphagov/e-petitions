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

      updates, params = [], {}
      updates << "email_count = COALESCE(email_count, 0) + 1"

      if constituency = signature.constituency
        updates << "constituency_id = :constituency_id"
        params[:constituency_id] = constituency.external_id
      end

      signature.update_all([updates.join(", "), params])
    end
  end

  private

  def rate_limit
    @rate_limit ||= RateLimit.first_or_create!
  end
end
