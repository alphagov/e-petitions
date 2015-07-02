class Admin::GovernmentResponseController < Admin::AdminController
  respond_to :html
  before_action :fetch_petition
  before_action :fetch_government_response

  def show
    render 'admin/petitions/show'
  end

  def update
    if @government_response.update_attributes(government_response_params)
      EmailThresholdResponseJob.run_later_tonight(@petition)
      redirect_to [:admin, @petition], notice: 'Email will be sent overnight'
    else
      render 'admin/petitions/show'
    end
  end

  private

  def fetch_petition
    @petition = Petition.moderated.find(params[:petition_id])
  end

  def fetch_government_response
    @government_response = @petition.government_response || @petition.build_government_response
  end

  def government_response_params
    params.require(:government_response).permit(:summary, :details)
  end
end
