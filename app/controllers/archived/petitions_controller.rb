class Archived::PetitionsController < ApplicationController
  respond_to :html, :json

  before_action :fetch_petitions, only: [:index]
  before_action :fetch_petition, only: [:show]

  def index
    respond_with(@petitions)
  end

  def show
    respond_with(@petition)
  end

  private

  def fetch_petitions
    @petitions = ArchivedPetition.search(params)
  end

  def fetch_petition
    @petition = ArchivedPetition.find(params[:id])
  end
end
