class Admin::DebateOutcomesController < Admin::AdminController
  respond_to :html
  before_action :fetch_petition
  before_action :fetch_debate_outcome

  def show
    render 'admin/petitions/show'
  end

  def update
    if @debate_outcome.update(debate_outcome_params)
      EmailDebateOutcomesJob.run_later_tonight(@petition)
      redirect_to [:admin, @petition], notice: 'Email will be sent overnight'
    else
      render 'admin/petitions/show'
    end
  end

  private

  def fetch_petition
    @petition = Petition.debateable.find(params[:petition_id])
  end

  def fetch_debate_outcome
    @debate_outcome = @petition.debate_outcome || @petition.build_debate_outcome
  end

  def debate_outcome_params
    params.require(:debate_outcome).permit(
      :debated_on, :overview, :transcript_url, :video_url
    )
  end
end
