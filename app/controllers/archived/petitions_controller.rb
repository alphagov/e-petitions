class Archived::PetitionsController < ApplicationController
  def index
    @petitions = ArchivedPetition.by_most_signatures.paginate(page: params[:page], per_page: params[:per_page] || 20)
  end

  def show
    @petition = ArchivedPetition.find(params[:id])
  end

  def search
    @petitions = ArchivedPetition.search(params)
  end
end
