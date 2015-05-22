class StaticPagesController < ApplicationController
  caches_page :accessibility, :how_it_works, :terms_and_conditions, :privacy_policy
  caches_action :home, :expires_in => 5.minutes

  def home
    all_trending_petitions = TrendingPetition.order("signatures_in_last_hour desc").limit(12)
    @trending_petitions   = all_trending_petitions[0..5]
    @additional_petitions = all_trending_petitions[6..11]
  end

end
