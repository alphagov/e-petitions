class SearchController < ApplicationController
  respond_to :html

  def search
    @petitions = PetitionSearch.new(params)
  end
end
