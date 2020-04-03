require 'csv'

class PetitionsController < ApplicationController
  before_action :redirect_to_valid_state, only: [:index]
  before_action :do_not_cache, except: [:index, :show]
  before_action :set_cors_headers, only: [:index, :show, :count], if: :json_request?

  before_action :redirect_to_home_page_if_dissolved, only: [:new, :check, :check_results, :create]
  before_action :redirect_to_home_page_unless_opened, only: [:index, :new, :check, :check_results, :create]
  before_action :redirect_to_archived_petition_if_archived, only: [:show]

  before_action :retrieve_petitions, only: [:index]
  before_action :retrieve_petition, only: [:show, :count, :gathering_support, :moderation_info]
  before_action :build_petition_creator, only: [:check, :check_results, :new, :create]

  before_action :redirect_to_stopped_page, if: :stopped?, only: [:moderation_info, :show]
  before_action :redirect_to_gathering_support_url, if: :collecting_sponsors?, only: [:moderation_info, :show]
  before_action :redirect_to_moderation_info_url, if: :in_moderation?, only: [:gathering_support, :show]
  before_action :redirect_to_petition_url, if: :moderated?, only: [:gathering_support, :moderation_info]

  after_action :set_content_disposition, if: :csv_request?, only: [:index]

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

  def count
    respond_to do |format|
      format.json
    end
  end

  def check
    respond_to do |format|
      format.html
    end
  end

  def check_results
    respond_to do |format|
      format.html
    end
  end

  def new
    respond_to do |format|
      format.html
    end
  end

  def create
    if @new_petition.save
      redirect_to thank_you_petition_url(@new_petition)
    else
      respond_to do |format|
        format.html { render :new }
      end
    end
  end

  def gathering_support
    respond_to do |format|
      format.html
    end
  end

  def moderation_info
    respond_to do |format|
      format.html
    end
  end

  def thank_you
    respond_to do |format|
      format.html
    end
  end

  protected

  def petition_id
    params[:id].to_i
  end

  def redirect_to_home_page_if_dissolved
    redirect_to home_url if Parliament.dissolved?
  end

  def redirect_to_home_page_unless_opened
    redirect_to home_url unless Parliament.opened?
  end

  def request_format
    request.format.json? ? :json : nil
  end

  def redirect_to_archived_petition_if_archived
    if petition = Archived::Petition.find_by(id: petition_id)
      redirect_to archived_petition_url(petition_id, format: request_format) if petition.parliament.archived?
    end
  end

  def retrieve_petitions
    scope = Petition.visible

    if json_request?
      scope = scope.preload(:creator, :rejection, :government_response, :debate_outcome)
    end

    @petitions = scope.search(params)
  end

  def retrieve_petition
    @petition = Petition.show.find(petition_id)
  end

  def build_petition_creator
    @new_petition = PetitionCreator.new(params, request)
  end

  def redirect_to_valid_state
    if state_present? && !valid_state?
      redirect_to petitions_url(search_params(state: :all))
    end
  end

  def state_present?
    params[:state].present?
  end

  def valid_state?
    public_petition_facets.include?(params[:state].to_sym)
  end

  def search_params(overrides = {})
    params.permit(:page, :q, :state).merge(overrides)
  end

  def collecting_sponsors?
    @petition.collecting_sponsors?
  end

  def redirect_to_gathering_support_url
    redirect_to gathering_support_petition_url(@petition)
  end

  def in_moderation?
    @petition.in_moderation?
  end

  def redirect_to_moderation_info_url
    redirect_to moderation_info_petition_url(@petition)
  end

  def moderated?
    @petition.moderated?
  end

  def stopped?
    @petition.stopped?
  end

  def redirect_to_stopped_page
    redirect_to home_url
  end

  def redirect_to_petition_url
    redirect_to petition_url(@petition)
  end

  def csv_filename
    "#{@petitions.scope}-petitions.csv"
  end

  def set_content_disposition
    response.headers['Content-Disposition'] = "attachment; filename=#{csv_filename}"
  end
end
