class SponsorSignedEmailBelowThresholdEmailJob < NotifyJob
  self.template = :sponsor_signed_email_below_threshold

  def perform(creator, sponsor)
    if sponsor.validated?
      super
    end
  end

  def personalisation(creator, petition, sponsor)
    I18n.with_locale(petition.locale) do
      {
        sponsor: sponsor.name,
        creator: creator.name,
        action:  petition.action,
        sponsor_count_en: sponsor_count(petition, :"en-GB"),
        sponsor_count_cy: sponsor_count(petition, :"cy-GB"),
        url_en:  help_en_url(anchor: 'standards'),
        url_cy:  help_cy_url(anchor: 'standards')
      }
    end
  end

  private

  def sponsor_count(petition, locale)
    I18n.t(
      :sponsor_count,
      scope: :"notify.strings",
      count: petition.sponsor_count,
      locale: locale
    )
  end
end
