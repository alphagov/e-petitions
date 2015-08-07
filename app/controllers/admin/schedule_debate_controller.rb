class Admin::ScheduleDebateController < Admin::AdminController
  respond_to :html
  before_action :fetch_petition

  def show
    render 'admin/petitions/show'
  end

  def update
    if @petition.update_attributes(params_for_update)
      EmailDebateScheduledJob.run_later_tonight(petition: @petition)
      redirect_to [:admin, @petition], notice: "Email will be sent overnight"
    else
      render 'admin/petitions/show'
    end
  end

  private
  def fetch_petition
    @petition = Petition.find(params[:petition_id])
  end

  def params_for_update
    params.
      require(:petition).
      permit(:scheduled_debate_date)
  end
end
