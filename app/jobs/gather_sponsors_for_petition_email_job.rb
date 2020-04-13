class GatherSponsorsForPetitionEmailJob < NotifyJob
  self.template = :gather_sponsors_for_petition

  def personalisation(signature, petition)
    {
      action:  petition.action, content: petition.content, creator: signature.name,
      url_en:  new_petition_sponsor_en_url(petition, token: petition.sponsor_token),
      url_cy:  new_petition_sponsor_cy_url(petition, token: petition.sponsor_token)
    }
  end

  def template
    if moderation_delay?
      :"#{super}_moderation_delay"
    elsif christmas_period?
      :"#{super}_christmas"
    elsif easter_period?
      :"#{super}_easter"
    else
      super
    end
  end
end
