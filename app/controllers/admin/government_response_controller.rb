class Admin::GovernmentResponseController < Admin::AdminController
  respond_to :html
  before_action :fetch_petition
  before_action :fetch_government_response

  def show
    render 'admin/petitions/show'
  end

  def update
    if @government_response.update_attributes(government_response_params)
      if send_email_to_petitioners?
        EmailThresholdResponseJob.run_later_tonight(petition: @petition)
        message = 'Email will be sent overnight'
      else
        message = 'Updated government response successfully'
      end

      redirect_to [:admin, @petition], notice: message
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

  def send_email_to_petitioners?
    params.key?(:save_and_email)
  end
end
