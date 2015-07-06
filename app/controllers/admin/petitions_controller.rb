class Admin::PetitionsController < Admin::AdminController
  respond_to :html

  def index
    if filter_by_tag?
      petitions_by_tag
    else
      petitions_by_filter_or_keyword_search
    end
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
      redirect_to admin_petition_url(@petition), notice: "Email will be sent overnight"
    else
      render :edit_scheduled_debate_date
    end
  end

  protected
  def filter_by_tag?
    params[:t].present? && !(filter_by_state? || filter_by_keyword?)
  end

  def filter_by_state?
    params[:state].present?
  end

  def filter_by_keyword?
    params[:q].present?
  end

  def petitions_by_filter_or_keyword_search
    @petitions = Petition.search(params.merge(count: 50))
    @query = params[:q]
  end

  def petitions_by_tag
    @petitions = Petition.tagged_with(params[:t]).paginate(page: params[:page], per_page: 50)
    @query = Petition.sanitized_tag(params[:t])
  end

  def fetch_petition_for_scheduled_debate_date
    @petition = Petition.find(params[:id])
    raise ActiveRecord::RecordNotFound unless @petition.can_have_debate_added?
  end

  def update_scheduled_debate_date_params
    params.require(:petition).permit(:scheduled_debate_date)
  end
end
