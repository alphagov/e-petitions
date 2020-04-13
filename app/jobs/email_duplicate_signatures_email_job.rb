class EmailDuplicateSignaturesEmailJob < NotifyJob
  self.template = :email_duplicate_signatures

  def perform(signature)
    super && increment_counter(signature)
  end

  def personalisation(signature, petition)
    {
      action_en:  petition.action_en, action_cy: petition.action_cy,
      url_en:  petition_en_url(petition), url_cy:  petition_cy_url(petition)
    }
  end

  private

  def increment_counter(signature)
    Signature.increment_counter(:email_count, signature.id)
  end
end
