class PetitionsController < ApplicationController
  include ManagingMoveParameter

  respond_to :html

  def index
    @petitions = Petition.visible.search(params)
  end

  def show
    begin
      respond_with @petition = Petition.visible.find(params[:id])
    rescue ActiveRecord::RecordNotFound => e
      if @petition = ArchivedPetition.find_by_id(params[:id])
        redirect_to archived_petition_url(@petition)
      else
        raise e
      end
    end
  end

  def new
    assign_title
    assign_stage
    @stage_manager = Staged::PetitionCreator.manager(petition_params_for_new, request, params[:stage], params[:move])
    respond_with @stage_manager.stage_object
  end

  def create
    assign_move
    assign_stage
    @stage_manager = Staged::PetitionCreator.manager(petition_params_for_create, request, params[:stage], params[:move])
    if @stage_manager.create_petition
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

  def resend_confirmation_email
    @petition = Petition.visible.find(params[:id])
    SignatureConfirmer.new(@petition, params[:confirmation_email], PetitionMailer, EMAIL_REGEX).confirm!
  end

  def moderation_info
    @petition = Petition.find(params[:id])
  end

  protected

  def parse_emails(emails)
    emails.strip.split(/\r?\n/).map { |e| e.strip }
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

  def assign_stage
    return if Staged::PetitionCreator.stages.include? params[:stage]
    params[:stage] = 'petition'
  end

  def send_email_to_gather_sponsors(petition)
    PetitionMailer.gather_sponsors_for_petition(petition).deliver_now
  end

  def parse_emails(emails)
    emails.strip.split(/\r?\n/).map { |e| e.strip }
  end
end
