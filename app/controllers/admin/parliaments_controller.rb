class Admin::ParliamentsController < Admin::AdminController
  before_action :require_sysadmin
  before_action :fetch_parliament

  def show
    respond_to do |format|
      format.html
    end
  end

  def update
    respond_to do |format|
      format.html do
        @parliament.assign_attributes(parliament_params)

        if @parliament.save(context: parliament_context)
          if perform_parliament_action!
            redirect_to admin_parliament_url(tab: params[:tab]), notice: parliament_action_notice
          else
            redirect_to admin_parliament_url(tab: params[:tab]), alert: parliament_action_alert
          end
        else
          render :show, alert: :parliament_not_updated
        end
      end
    end
  end

  private

  def fetch_parliament
    @parliament = Parliament.instance
  end

  def parliament_params
    params.require(:parliament).permit(
      :government, :state_opening_at, :opening_at,
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

  def perform_parliament_action!
    case button_param
    when "send_emails"
      @parliament.send_emails!
    when "schedule_closure"
      @parliament.schedule_closure!
    when "archive_petitions"
      @parliament.start_archiving!
    when "anonymize_petitions"
      @parliament.start_anonymizing!
    when "archive_parliament"
      @parliament.archive!
    else
      true
    end
  end

  def parliament_context
    case button_param
    when "send_emails"
      :send_emails
    when "schedule_closure"
      :schedule_closure
    when "archive_petitions"
      :archive_petitions
    when "archive_parliament"
      :archive_parliament
    when "anonymize_petitions"
      :anonymize_petitions
    else
      nil
    end
  end

  def parliament_action_notice
    case button_param
    when "send_emails" then
      :creators_emailed
    when "schedule_closure"
      :closure_scheduled
    when "archive_petitions"
      :petitions_archiving
    when "archive_parliament"
      :parliament_archived
    when "anonymize_petitions"
      :petitions_anonymizing
    else
      :parliament_updated
    end
  end

  def parliament_action_alert
    case button_param
    when "send_emails" then
      :creators_not_emailed
    when "schedule_closure"
      :closure_not_scheduled
    when "archive_petitions"
      :petitions_not_archiving
    when "archive_parliament"
      :parliament_not_archived
    when "anonymize_petitions"
      :petitions_not_anonymizing
    else
      :parliament_not_updated
    end
  end

  def button_param
    params.fetch(:button, "save")
  end
end
