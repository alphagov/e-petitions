class StaticPagesController < ApplicationController
  caches_page :accessibility, :how_it_works, :terms_and_conditions, :cookies, :privacy_policy
  caches_action :home, :expires_in => 5.minutes

  def home
    @trending_petitions   = Petition.last_hour_trending
  end

end
