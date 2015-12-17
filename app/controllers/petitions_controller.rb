class PetitionsController < ApplicationController
  include ManagingMoveParameter

  before_action :avoid_unknown_state_filters, only: :index
  before_action :do_not_cache, except: %i[index show]

  before_action :retrieve_petition, only: [:show, :moderation_info]
  before_action :redirect_to_moderation_info_url, if: :not_moderated?, only: :show
  before_action :redirect_to_petition_url, if: :moderated?, only: :moderation_info

  respond_to :html
  respond_to :json, only: [:index, :show]

  def index
    @petitions = Petition.visible.search(params)
  end

  def show
    respond_with @petition
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
      render :new
    end
  end

  def check
  end

  def check_results
    @petitions = Petition.visible.search(params.merge(count: 3))
  end

  def moderation_info
    @petition = Petition.find(params[:id])
  end

  protected

  def retrieve_petition
    @petition = Petition.show.find(params[:id])
  rescue ActiveRecord::RecordNotFound => e
    if @petition = ArchivedPetition.find_by_id(params[:id])
      redirect_to archived_petition_url(@petition)
    else
      raise e
    end
  end

  def avoid_unknown_state_filters
    return if params[:state].blank?
    redirect_to url_for(params.merge(state: 'all')) unless public_petition_facets.include? params[:state].to_sym
  end

  def not_moderated?
    !@petition.moderated?
  end

  def redirect_to_moderation_info_url
    redirect_to moderation_info_petition_url(@petition)
  end

  def moderated?
    @petition.moderated?
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
               :postcode, :country, :uk_citizenship
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
end
