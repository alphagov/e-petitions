class Archived::PetitionsController < ApplicationController
  def index
    if params[:q].blank?
      @petitions = ArchivedPetition.search(params.merge({state: 'by_most_signatures'}))
    else
      @petitions = ArchivedPetition.search(params)
    end
  end

  def show
    @petition = ArchivedPetition.find(params[:id])
  end
end
