class Admin::DebateOutcomesController < Admin::AdminController
  respond_to :html
  before_action :fetch_petition

  def show
    fetch_debate_outcome
  end

  def update
    fetch_debate_outcome
    if @debate_outcome.update_attributes(params_for_update)
      EmailDebateOutcomesJob.run_later_tonight(@petition)
      redirect_to [:admin, @petition], notice: 'Email will be sent overnight'
    else
      render :show
    end
  end

  private
  def fetch_petition
    @petition = Petition.find(params[:petition_id])
    raise ActiveRecord::RecordNotFound unless @petition.can_have_debate_added?
  end

  def fetch_debate_outcome
    @debate_outcome = @petition.debate_outcome || @petition.build_debate_outcome
  end

  def params_for_update
    params.
      require(:debate_outcome).
      permit(:debated_on, :overview, :transcript_url, :video_url)
  end
end
