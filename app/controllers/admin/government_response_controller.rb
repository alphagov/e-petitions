class Admin::GovernmentResponseController < Admin::AdminController
  respond_to :html
  before_action :fetch_petition

  def show
  end

  def update
    if @petition.update_attributes(params_for_update_response)
      # if email signees has been selected then set up a delayed job to email out to all signees who opted in
      if @petition.email_signees
        # run the job at some random point beween midnight and 4 am
        EmailThresholdResponseJob.run_later_tonight(@petition)
      end

      redirect_to [:admin, @petition]
    else
      render :show
    end
  end

  private
  def fetch_petition
    @petition = Petition.selectable.find(params[:petition_id])
  end

  def assign_email_signees_param
    return unless params[:petition]
    params[:petition][:email_signees] = params[:petition][:email_signees] == '1'
  end

  def params_for_update_response
    assign_email_signees_param
    params.
      require(:petition).
      permit(:response, :response_summary, :email_signees)
  end
end
