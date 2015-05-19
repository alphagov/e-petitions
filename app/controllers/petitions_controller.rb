class PetitionsController < ApplicationController
  before_filter :sanitise_page_param
  before_filter :sanitise_state_param
  caches_action_with_params :index

  caches_page :show

  respond_to :html

  def index
    @petition_search = PetitionSearch.new(params)
  end

  def show
    respond_with @petition = Petition.visible.find(params[:id])
  end

  def new
    assign_title
    assign_stage
    @stage_manager = Staged::PetitionCreator.new(petition_params_for_new, request, params[:stage], params[:move])
    respond_with @stage_manager.stage_object
  end

  def create
    assign_move
    assign_stage
    @stage_manager = Staged::PetitionCreator.new(petition_params_for_create, request, params[:stage], params[:move])
    if @stage_manager.create_petition
      send_email_to_verify_petition_creator(@stage_manager.petition)
      redirect_to thank_you_petition_path(@stage_manager.petition, :secure => true)
    else
      render :new
    end
  end

  def check
  end

  def check_results
    search_params = params
    search_params[:q] = search_params[:search]
    search_params[:per_page] = 10
    @petition_search = PetitionSearch.new(search_params)
  end

  def resend_confirmation_email
    @petition = Petition.visible.find(params[:id])
    SignatureConfirmer.new(@petition, params[:confirmation_email], PetitionMailer, EMAIL_REGEX).confirm!
  end

  protected

  def sanitise_state_param
    params[:state] = State::SEARCHABLE_STATES.include?(params[:state]) ? params[:state] : 'open'
  end

  def parse_emails(emails)
    emails.strip.split(/\r?\n/).map { |e| e.strip }
  end

  def send_email_to_verify_petition_creator(petition)
    PetitionMailer.email_confirmation_for_creator(petition.creator_signature).deliver_now
  end

  def petition_params_for_new
    params.
      fetch('petition', {}).
      permit(:title)
  end

  def petition_params_for_create
    params.
      require(:petition).
      permit(:title, :action, :description, :duration, :sponsor_emails,
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

  def assign_title
    return if params[:title].blank?
    title = params.delete(:title)
    params[:petition] ||= {}
    params[:petition][:title] = title
  end

  def assign_move
    return if ['next', 'back'].include? params[:move]
    params[:move] = 'next'
  end

  def assign_stage
    return if Staged::PetitionCreator.stages.include? params[:stage]
    params[:stage] = 'petition'
  end

  def send_email_to_verify_petition_creator(petition)
    PetitionMailer.email_confirmation_for_creator(petition.creator_signature).deliver_now
  end

  def parse_emails(emails)
    emails.strip.split(/\r?\n/).map { |e| e.strip }
  end
end
