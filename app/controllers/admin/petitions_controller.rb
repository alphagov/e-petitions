class Admin::PetitionsController < Admin::AdminController
  respond_to :html

  def index
    @petitions = Petition.selectable.search(params.merge(count: 50))
  end

  def show
    @petition = Petition.find(params[:id])
  end

  def edit_scheduled_debate_date
    fetch_petition_for_scheduled_debate_date
  end

  def update_scheduled_debate_date
    fetch_petition_for_scheduled_debate_date
    if @petition.update(update_scheduled_debate_date_params)
      EmailDebateScheduledJob.run_later_tonight(@petition)
      redirect_to admin_petition_path(@petition), notice: "Email will be sent overnight"
    else
      render :edit_scheduled_debate_date
    end
  end

  protected

  def fetch_petition_for_scheduled_debate_date
    @petition = Petition.find(params[:id])
    raise ActiveRecord::RecordNotFound unless @petition.can_have_debate_added?
  end

  def update_scheduled_debate_date_params
    params.require(:petition).permit(:scheduled_debate_date)
  end
end
