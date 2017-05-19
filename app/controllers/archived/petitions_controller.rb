class Archived::PetitionsController < ApplicationController
  respond_to :html, :json

  before_action :fetch_parliament
  before_action :fetch_petitions, only: [:index]
  before_action :fetch_petition, only: [:show]

  before_action :set_cors_headers, only: [:index, :show], if: :json_request?

  def index
    respond_with(@petitions)
  end

  def show
    respond_with(@petition)
  end

  private

  def parliament_id
    params[:parliament].to_i
  end

  def fetch_parliament
    if params.key?(:parliament)
      @parliament = Parliament.archived.find(parliament_id)
    else
      @parliament = Parliament.archived.first
    end
  end

  def fetch_petitions
    @petitions = @parliament.petitions.search(params)
  end

  def fetch_petition
    @petition = @parliament.petitions.find(params[:id])
  end
end
