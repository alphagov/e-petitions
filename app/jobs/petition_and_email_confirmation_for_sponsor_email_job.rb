class PetitionAndEmailConfirmationForSponsorEmailJob < NotifyJob
  self.template = :petition_and_email_confirmation_for_sponsor

  include RateLimiting

  def personalisation(signature, petition)
    I18n.with_locale(petition.locale) do
      {
        action:  petition.action, content: petition.content, creator: petition.creator_name,
        url_en:  verify_sponsor_en_url(signature, token: signature.perishable_token),
        url_cy:  verify_sponsor_cy_url(signature, token: signature.perishable_token)
      }
    end
  end
end
