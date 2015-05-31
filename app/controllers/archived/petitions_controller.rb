class Archived::PetitionsController < ApplicationController
  def index
  end

  def show
    @petition = ArchivedPetition.find(params[:id])
  end

  def search
    @petitions = ArchivedPetition.search(params)
  end
end
