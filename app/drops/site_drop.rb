class SiteDrop < ApplicationDrop
  def initialize(site)
    @site = site
  end

  with_options to: :@site do
    delegate :maximum_number_of_sponsors
    delegate :threshold_for_moderation
  end

  def moderation_delay
    @moderation_delay ||= Petition.in_moderation.count >= @site.threshold_for_moderation_delay
  end

  def home_url
    routes.home_url
  end

  def standards_url
    routes.help_url(anchor: "standards")
  end
end
