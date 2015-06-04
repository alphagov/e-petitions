class StaticPagesController < ApplicationController
  caches_page :help
  caches_action :home, :expires_in => 5.minutes

  def home
    @trending_petitions   = Petition.last_hour_trending
  end

end
