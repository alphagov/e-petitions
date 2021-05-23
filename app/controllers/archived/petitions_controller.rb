require 'csv'

class Archived::PetitionsController < ApplicationController
  before_action :redirect_to_valid_state, only: [:index]
  before_action :fetch_parliament, only: [:index]
  before_action :fetch_petitions, only: [:index]
  before_action :fetch_petition, only: [:show]

  before_action :set_cors_headers, only: [:index, :show], if: :json_request?
  after_action :set_content_disposition, if: :csv_request?, only: [:index]

  helper_method :archived_petition_facets

  def index
    respond_to do |format|
      format.html
      format.json
      format.csv
    end
  end

  def show
    respond_to do |format|
      format.html
      format.json
    end
  end

  private

  def parliament_id
    Integer(params[:parliament])
  rescue ArgumentError, TypeError => e
    raise ActionController::BadRequest, "Invalid petition id: #{params[:parliament]}"
  end

  def petition_id
    Integer(params[:id])
  rescue ArgumentError => e
    raise ActionController::BadRequest, "Invalid petition id: #{params[:id]}"
  end

  def fetch_parliament
    if params.key?(:parliament)
      @parliament = Parliament.archived.find(parliament_id)
    else
      @parliament = Parliament.archived.first
    end
  end

  def fetch_petitions
    if params.key?(:parliament)
      scope = Archived::Petition.visible
    else
      scope = @parliament.petitions.visible
    end

    if json_request?
      scope = scope.preload(:creator, :rejection, :government_response, :debate_outcome)
    end

    @petitions = scope.search(params)
  end

  def fetch_petition
    @petition = Archived::Petition.visible.find(petition_id)
    @parliament = @petition.parliament

    unless @parliament.archived?
      redirect_to petition_url(petition_id)
    end
  end

  def csv_filename
    "#{@petitions.scope}-petitions-#{@parliament.period}.csv"
  end

  def redirect_to_valid_state
    if state_present? && !valid_state?
      redirect_to archived_petitions_url(search_params(state: :all))
    end
  end

  def state_present?
    params[:state].present?
  end

  def sanitized_state
    params[:state].to_s[0..30].to_sym
  end

  def valid_state?
    archived_petition_facets.include?(sanitized_state)
  end

  def search_params(overrides = {})
    params.permit(:page, :parliament, :q, :state).merge(overrides)
  end

  def archived_petition_facets
    I18n.t :archived, scope: :"petitions.facets", default: []
  end

  def set_content_disposition
    response.headers['Content-Disposition'] = "attachment; filename=#{csv_filename}"
  end
end
