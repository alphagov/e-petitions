class StaticPagesController < ApplicationController

  def home
    @trending_petitions   = Petition.last_hour_trending
  end

end
