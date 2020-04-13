class NotifySponsorThatPetitionIsPublishedEmailJob < NotifyJob
  self.template = :notify_sponsor_that_petition_is_published

  def personalisation(signature, petition)
    {
      sponsor: signature.name,
      action_en:  petition.action_en, action_cy: petition.action_cy,
      url_en:  petition_en_url(petition), url_cy:  petition_cy_url(petition)
    }
  end
end
