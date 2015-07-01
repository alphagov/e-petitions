class Admin::GovernmentResponseController < Admin::AdminController
  respond_to :html
  before_action :fetch_petition
  before_action :avoid_no_op_updates, only: :update

  def show
  end

  def update
    if @petition.update_attributes(params_for_update_response)
      # run the job at some random point beween midnight and 4 am
      EmailThresholdResponseJob.run_later_tonight(@petition)
      redirect_to [:admin, @petition], notice: 'Email will be sent overnight'
    else
      render :show
    end
  end

  private
  def fetch_petition
    @petition = Petition.selectable.find(params[:petition_id])
  end

  def avoid_no_op_updates
    redirect_to [:admin, @petition, :government_response] if params_for_update_response.values.all? &:blank?
  end

  def params_for_update_response
    @_params_for_update_response ||= params.
      require(:petition).
      permit(:response, :response_summary)
  end
end
