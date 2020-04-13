class NotifySignerOfNegativeDebateOutcomeEmailJob < NotifyJob
  self.template = :notify_signer_of_negative_debate_outcome

  def perform(signature, *args)
    if signature.notify_by_email?
      super
    end
  end

  def personalisation(signature, petition, outcome)
    {
      name: signature.name,
      action_en: petition.action_en, action_cy: petition.action_cy,
      overview_en: outcome.overview_en, overview_cy: outcome.overview_cy,
      petition_url_en: petition_en_url(petition),
      petition_url_cy: petition_cy_url(petition),
      petitions_committee_url_en: help_en_url(anchor: "petitions-committee"),
      petitions_committee_url_cy: help_cy_url(anchor: "petitions-committee"),
      unsubscribe_url_en: unsubscribe_signature_en_url(signature, token: signature.unsubscribe_token),
      unsubscribe_url_cy: unsubscribe_signature_cy_url(signature, token: signature.unsubscribe_token),
    }
  end
end
