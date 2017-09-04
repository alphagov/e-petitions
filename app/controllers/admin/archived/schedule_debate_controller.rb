class Admin::Archived::ScheduleDebateController < Admin::AdminController
  before_action :fetch_petition

  def show
    render 'admin/archived/petitions/show'
  end

  def update
    if @petition.update_attributes(params_for_update)
      if send_email_to_petitioners?
        ::Archived::EmailDebateScheduledJob.run_later_tonight(petition: @petition)
        message = :email_sent_overnight
      else
        message = :debate_date_updated
      end

      redirect_to admin_archived_petition_url(@petition), notice: message
    else
      render 'admin/archived/petitions/show'
    end
  end

  private

  def fetch_petition
    @petition = ::Archived::Petition.find(params[:petition_id])
  end

  def params_for_update
    params.require(:archived_petition).permit(:scheduled_debate_date)
  end

  def send_email_to_petitioners?
    params.key?(:save_and_email)
  end
end
