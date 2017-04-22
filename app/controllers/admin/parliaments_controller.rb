class Admin::ParliamentsController < Admin::AdminController
  respond_to :html

  before_action :require_sysadmin
  before_action :fetch_parliament

  def show
  end

  def update
    if @parliament.update(parliament_params)
      if email_creators?
        NotifyCreatorsThatParliamentIsDissolvingJob.perform_later
        redirect_to admin_root_url, notice: :creators_emailed
      else
        redirect_to admin_root_url, notice: :parliament_updated
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
    params.require(:parliament).permit(:dissolution_at, :dissolution_heading, :dissolution_message)
  end

  def email_creators?
    params.key?(:email_creators) && @parliament.dissolution_announced?
  end
end
