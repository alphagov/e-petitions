class Admin::ParliamentsController < Admin::AdminController
  before_action :require_sysadmin
  before_action :fetch_parliament

  def show
    respond_to do |format|
      format.html
    end
  end

  def update
    if @parliament.update(parliament_params)
      if send_emails?
        @parliament.send_emails!
        redirect_to admin_parliament_url(tab: params[:tab]), notice: :creators_emailed
      elsif schedule_closure?
        @parliament.schedule_closure!
        redirect_to admin_parliament_url(tab: params[:tab]), notice: :closure_scheduled
      elsif archive_petitions?
        @parliament.start_archiving!
        redirect_to admin_parliament_url(tab: params[:tab]), notice: :petitions_archiving
      elsif anonymize_petitions?
        @parliament.start_anonymizing!
        redirect_to admin_parliament_url(tab: params[:tab]), notice: :petitions_anonymizing
      elsif archive_parliament?
        @parliament.archive!
        redirect_to admin_parliament_url(tab: params[:tab]), notice: :parliament_archived
      else
        redirect_to admin_parliament_url(tab: params[:tab]), notice: :parliament_updated
      end
    else
      render :show
    end
  end

  private

  def fetch_parliament
    @parliament = Parliament.instance
  end

  def parliament_params
    params.require(:parliament).permit(
      :government, :opening_at,
      :dissolution_heading, :dissolution_message,
      :dissolved_heading, :dissolved_message,
      :dissolution_at, :dissolution_faq_url,
      :notification_cutoff_at, :registration_closed_at,
      :election_date, :show_dissolution_notification,
      :government_response_heading, :government_response_description,
      :government_response_status, :parliamentary_debate_heading,
      :parliamentary_debate_description, :parliamentary_debate_status
    )
  end

  def send_emails?
    params.key?(:send_emails) && @parliament.dissolution_at?
  end

  def schedule_closure?
    params.key?(:schedule_closure) && @parliament.dissolution_announced?
  end

  def archive_petitions?
    params.key?(:archive_petitions) && @parliament.can_archive_petitions?
  end

  def anonymize_petitions?
    params.key?(:anonymize_petitions) && Archived::Petition.can_anonymize?
  end

  def archive_parliament?
    params.key?(:archive_parliament) && @parliament.can_archive?
  end
end
