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

  def threshold_for_response
    @site.formatted_threshold_for_response
  end

  def threshold_for_debate
    @site.formatted_threshold_for_debate
  end

  def home_url
    routes.home_url
  end

  def standards_url
    routes.help_url(anchor: "standards")
  end

  def petitions_committee_url
    routes.help_url(anchor: "petitions-committee")
  end

  def check_petitions_url
    routes.check_petitions_url
  end
end
