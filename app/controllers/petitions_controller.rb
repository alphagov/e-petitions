class PetitionsController < ApplicationController
  before_filter :assign_departments, :only => [:new, :create]
  before_filter :sanitise_page_param
  caches_action_with_params :index

  caches_page :show

  respond_to :html

  include SearchResultsSetup

  def index
    results_for(Petition)
  end

  def show
    respond_with @petition = Petition.visible.find(params[:id])
  end

  def new
    assign_title
    assign_stage
    @stage_manager = StagedPetitionCreator.new(petition_params_for_new, request, params[:stage], params[:move])
    respond_with @stage_manager.stage_object
  end

  def create
    assign_move
    assign_stage
    @stage_manager = StagedPetitionCreator.new(petition_params_for_create, request, params[:stage], params[:move])
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
    @petition_search = PetitionResults.new(
      :search_term    => params[:search],
      :state => params[:state],
      :per_page       => 10,
      :page_number    => params[:page],
      :sort           => params[:sort],
      :order          => params[:order]
    )
  end

  def resend_confirmation_email
    @petition = Petition.visible.find(params[:id])
    SignatureConfirmer.new(@petition, params[:confirmation_email], PetitionMailer, Authlogic::Regex.email).confirm!
  end

  protected

  def assign_title
    return if params[:title].blank?
    title = params.delete(:title)
    params[:petition] ||= {}
    params[:petition][:title] = title
  end

  def petition_params_for_new
    params.
      fetch('petition', {}).
      permit(:title)
  end

  def petition_params_for_create
    params.
      require(:petition).
      permit(:title, :action, :description, :duration, :department_id,
             :sponsor_emails,
             creator_signature: [
               :name, :email, :email_confirmation, :address, :town,
               :postcode, :country, :uk_citizenship,
               :terms_and_conditions, :notify_by_email
             ]).tap do |sanitized|
               if sanitized['creator_signature'].present?
                 sanitized['creator_signature_attributes'] = sanitized.delete('creator_signature')
               end
               if sanitized['sponsor_emails']
                 sanitized['sponsor_emails'] = parse_emails(sanitized['sponsor_emails'])
               end
             end
  end

  def assign_move
    return if ['next', 'back'].include? params[:move]
    params[:move] = 'next'
  end

  def assign_stage
    return if StagedPetitionCreator.stages.include? params[:stage]
    params[:stage] = 'petition'
  end

  def send_email_to_verify_petition_creator(petition)
    PetitionMailer.email_confirmation_for_creator(petition.creator_signature).deliver_now
  end

  def parse_emails(emails)
    emails.strip.split(/\r?\n/).map { |e| e.strip }
  end
end

