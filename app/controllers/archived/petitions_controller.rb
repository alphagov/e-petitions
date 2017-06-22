require 'csv'

class Archived::PetitionsController < ApplicationController
  respond_to :html, :json
  respond_to :csv, only: [:index]

  before_action :redirect_to_index_page, unless: :valid_state?, only: [:index]
  before_action :fetch_parliament, only: [:index]
  before_action :fetch_petitions, only: [:index]
  before_action :fetch_petition, only: [:show]

  before_action :set_cors_headers, only: [:index, :show], if: :json_request?
  after_action :set_content_disposition, if: :csv_request?, only: [:index]

  helper_method :archived_petition_facets

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
    @petition = Archived::Petition.visible.find(params[:id])
    @parliament = @petition.parliament
  end

  def csv_filename
    "#{@petitions.scope}-petitions-#{@parliament.period}.csv"
  end

  def redirect_to_index_page
    redirect_to archived_petitions_url
  end

  def valid_state?
    params[:state] ? archived_petition_facets.include?(params[:state].to_sym) : true
  end

  def archived_petition_facets
    I18n.t :archived, scope: :"petitions.facets", default: []
  end

  def set_content_disposition
    response.headers['Content-Disposition'] = "attachment; filename=#{csv_filename}"
  end
end
