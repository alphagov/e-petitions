require 'csv'

class PetitionsController < ApplicationController
  include ManagingMoveParameter

  before_action :avoid_unknown_state_filters, only: :index
  before_action :do_not_cache, except: %i[index show]

  before_action :redirect_to_home_page, if: :parliament_dissolved?, only: [:new, :check, :check_results, :create]

  before_action :retrieve_petition, only: [:show, :count, :gathering_support, :moderation_info]
  before_action :redirect_to_stopped_page, if: :stopped?, only: [:moderation_info, :show]
  before_action :redirect_to_gathering_support_url, if: :collecting_sponsors?, only: [:moderation_info, :show]
  before_action :redirect_to_moderation_info_url, if: :in_moderation?, only: [:gathering_support, :show]
  before_action :redirect_to_petition_url, if: :moderated?, only: [:gathering_support, :moderation_info]

  before_action :set_cors_headers, only: [:index, :show, :count], if: :json_request?
  after_action :set_content_disposition, if: :csv_request?, only: [:index]

  respond_to :html
  respond_to :json, only: [:index, :show]
  respond_to :csv, only: [:index]

  def index
    @petitions = Petition.visible.search(params)
    respond_with @petitions
  end

  def show
    respond_with @petition
  end

  def count
    respond_to { |f| f.json }
  end

  def new
    assign_action
    assign_stage
    @stage_manager = Staged::PetitionCreator.manager(petition_params_for_new, request, params[:stage], params[:move])
    respond_with @stage_manager.stage_object
  end

  def create
    assign_move
    assign_stage
    @stage_manager = Staged::PetitionCreator.manager(petition_params_for_create, request, params[:stage], params[:move])
    if @stage_manager.create_petition
      @stage_manager.petition.creator_signature.store_constituency_id
      send_email_to_gather_sponsors(@stage_manager.petition)
      redirect_to thank_you_petition_url(@stage_manager.petition)
    else
      respond_to do |format|
        format.html { render :new }
      end
    end
  end

  def check
    respond_to do |format|
      format.html
    end
  end

  def check_results
    @petitions = Petition.visible.search(params.merge(count: 3))
    respond_to do |format|
      format.html
    end
  end

  def moderation_info
    @petition = Petition.find(params[:id])
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

  def retrieve_petition
    @petition = Petition.show.find(params[:id])
  rescue ActiveRecord::RecordNotFound => e
    if @petition = Archived::Petition.find_by_id(params[:id])
      redirect_to archived_petition_url(@petition)
    else
      raise e
    end
  end

  def avoid_unknown_state_filters
    return if params[:state].blank?
    redirect_to url_for(params.permit([:q, :state]).merge(state: 'all')) unless public_petition_facets.include? params[:state].to_sym
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

  def parse_emails(emails)
    emails.strip.split(/\r?\n/).map { |e| e.strip }
  end

  def petition_params_for_new
    params.
      fetch('petition', {}).
      permit(:action)
  end

  def petition_params_for_create
    params.
      require(:petition).
      permit(:action, :background, :additional_details, :duration, :sponsor_emails,
             creator_signature: [
               :name, :email, :email_confirmation,
               :postcode, :location_code, :uk_citizenship
             ]).tap do |sanitized|
               if sanitized['creator_signature'].present?
                 sanitized['creator_signature_attributes'] = sanitized.delete('creator_signature')
               end
               if sanitized['sponsor_emails']
                 sanitized['sponsor_emails'] = parse_emails(sanitized['sponsor_emails'])
               end
             end
  end

  def assign_action
    return if params[:petition_action].blank?
    petition_action = params.delete(:petition_action)
    params[:petition] ||= {}
    params[:petition][:action] = petition_action
  end

  def assign_stage
    return if Staged::PetitionCreator.stages.include? params[:stage]
    params[:stage] = 'petition'
  end

  def send_email_to_gather_sponsors(petition)
    GatherSponsorsForPetitionEmailJob.perform_later(petition)
  end

  def parse_emails(emails)
    emails.strip.split(/\r?\n/).map { |e| e.strip }
  end

  def csv_filename
    "#{@petitions.scope}-petitions.csv"
  end

  def set_content_disposition
    response.headers['Content-Disposition'] = "attachment; filename=#{csv_filename}"
  end
end
