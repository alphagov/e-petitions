class EmailDuplicateSponsorEmailJob < NotifyJob
  self.template = :email_duplicate_sponsor

  def perform(signature)
    super && increment_counter(signature)
  end

  def personalisation(signature, petition)
    I18n.with_locale(petition.locale) do
      { action:  petition.action }
    end
  end

  private

  def increment_counter(signature)
    Signature.increment_counter(:email_count, signature.id)
  end
end
