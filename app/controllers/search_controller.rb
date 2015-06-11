class SearchController < ApplicationController
  respond_to :html

  def search
    @petitions = Petition.visible.search(params)
  end
end
