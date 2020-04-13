class EmailConfirmationForSignerEmailJob < NotifyJob
  self.template = :email_confirmation_for_signer

  include RateLimiting

  def personalisation(signature, petition)
    {
      action_en:  petition.action_en, action_cy: petition.action_cy,
      url_en:  verify_signature_en_url(signature, token: signature.perishable_token),
      url_cy:  verify_signature_cy_url(signature, token: signature.perishable_token)
    }
  end
end
