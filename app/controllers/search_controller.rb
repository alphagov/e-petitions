class SearchController < ApplicationController
  respond_to :html

  def search
    @petition_search = PetitionSearch.new(params)
  end
end
