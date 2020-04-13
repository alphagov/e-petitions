class NotifyCreatorOfDebateScheduledEmailJob < NotifyJob
  self.template = :notify_creator_of_debate_scheduled

  def perform(signature, *args)
    if signature.notify_by_email?
      super
    end
  end

  def personalisation(signature, petition)
    {
      name: signature.name,
      action_en: petition.action_en, action_cy: petition.action_cy,
      petition_url_en: petition_en_url(petition),
      petition_url_cy: petition_cy_url(petition),
      debate_date_en: short_date(petition.scheduled_debate_date, :"en-GB"),
      debate_date_cy: short_date(petition.scheduled_debate_date, :"cy-GB"),
      unsubscribe_url_en: unsubscribe_signature_en_url(signature, token: signature.unsubscribe_token),
      unsubscribe_url_cy: unsubscribe_signature_cy_url(signature, token: signature.unsubscribe_token),
    }
  end

  private

  def short_date(date, locale)
    I18n.l(date, format: "%-d %B %Y", locale: locale)
  end
end
