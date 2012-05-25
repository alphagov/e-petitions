class SearchController < ApplicationController
  respond_to :html

  def search
    @petition_search = PetitionResults.new(
      :search_term    => params[:q],
      :state => params[:state],
      :per_page       => 20,
      :page_number    => params[:page],
      :sort           => params[:sort],
      :order          => params[:order]
    )
  end
end
