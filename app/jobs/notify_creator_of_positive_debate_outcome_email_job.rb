class NotifyCreatorOfPositiveDebateOutcomeEmailJob < NotifyJob
  self.template = :notify_creator_of_positive_debate_outcome

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
      transcript_url_en: outcome.transcript_url_en, transcript_url_cy: outcome.transcript_url_cy,
      video_url_en: outcome.video_url_en, video_url_cy: outcome.video_url_cy,
      debate_pack_url_en: outcome.debate_pack_url_en, debate_pack_url_cy: outcome.debate_pack_url_cy,
      petition_url_en: petition_en_url(petition), petition_url_cy: petition_cy_url(petition),
      unsubscribe_url_en: unsubscribe_signature_en_url(signature, token: signature.unsubscribe_token),
      unsubscribe_url_cy: unsubscribe_signature_cy_url(signature, token: signature.unsubscribe_token),
    }
  end
end
