class NotifySponsorThatPetitionWasRejectedEmailJob < NotifyJob
  self.template = :notify_sponsor_that_petition_was_rejected

  def personalisation(signature, petition, rejection)
    I18n.with_locale(petition.locale) do
      if insufficient_petition?
        {
          sponsor: signature.name,
          action_en: petition.action_en, action_cy: petition.action_cy,
          content_en: rejection.content_en, content_cy: rejection.content_cy,
          url_en: petition_en_url(petition), url_cy: petition_cy_url(petition),
          standards_url_en: help_en_url(anchor: "standards"),
          standards_url_cy: help_cy_url(anchor: "standards")
        }
      else
        {
          sponsor: signature.name, action: petition.action,
          content_en: rejection.content_en, content_cy: rejection.content_cy,
          url_en: petition_en_url(petition), url_cy: petition_cy_url(petition),
          standards_url_en: help_en_url(anchor: "standards"),
          standards_url_cy: help_cy_url(anchor: "standards")
        }
      end
    end
  end

  def template
    if hidden_petition?
      :"#{super}_hidden"
    elsif insufficient_petition?
      :"#{super}_insufficient"
    else
      super
    end
  end

  private

  def hidden_petition?
    arguments.first.petition.hidden?
  end

  def insufficient_petition?
    arguments.last.code == "insufficient"
  end
end
