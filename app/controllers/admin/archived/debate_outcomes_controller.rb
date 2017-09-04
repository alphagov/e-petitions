class Admin::Archived::DebateOutcomesController < Admin::AdminController
  before_action :fetch_petition
  before_action :fetch_debate_outcome

  rescue_from ActiveRecord::RecordNotUnique do
    @debate_outcome = @petition.debate_outcome(true) and update
  end

  def show
    render 'admin/archived/petitions/show'
  end

  def update
    if @debate_outcome.update(debate_outcome_params)
      if send_email_to_petitioners?
        ::Archived::EmailDebateOutcomesJob.run_later_tonight(petition: @petition)
        message = :email_sent_overnight
      else
        message = :debate_outcome_updated
      end

      redirect_to admin_archived_petition_url(@petition), notice: message
    else
      render 'admin/archived/petitions/show'
    end
  end

  private

  def fetch_petition
    @petition = ::Archived::Petition.debateable.find(params[:petition_id])
  end

  def fetch_debate_outcome
    @debate_outcome = @petition.debate_outcome || @petition.build_debate_outcome
  end

  def debate_outcome_params
    params.require(:archived_debate_outcome).permit(*debate_outcome_attributes)
  end

  def debate_outcome_attributes
    %i[debated_on overview transcript_url video_url debate_pack_url debated commons_image]
  end

  def send_email_to_petitioners?
    params.key?(:save_and_email)
  end
end
