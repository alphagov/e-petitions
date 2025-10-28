require 'csv'

class Archived::PetitionsController < PublicController
  before_action :redirect_to_valid_state, only: [:index]
  before_action :redirect_to_show_page_if_petition_exists, only: [:index]
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
    @petitions = Archived::PetitionSearch.new(params)
  end

  def fetch_petition
    if Archived::Petition.removed?(petition_id)
      raise Site::PetitionRemoved, "Archived petition #{petition_id} has been removed"
    end

    @petition = Archived::Petition.visible.find(petition_id)
    @parliament = @petition.parliament

    unless @parliament.archived?
      redirect_to petition_url(petition_id)
    end
  end

  def csv_filename
    "filtered-archived-petitions.csv"
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

  def redirect_to_show_page_if_petition_exists
    if query_param.match?(/^\d+$/)
      redirect_to petition_url(query_param) if Archived::Petition.visible.exists?(query_param)
    end
  end

  def query_param
    params.fetch(:query, params.fetch(:q, ""))
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
