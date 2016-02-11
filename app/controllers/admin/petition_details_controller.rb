class Admin::PetitionDetailsController < Admin::AdminController
  respond_to :html
  before_action :fetch_petition

  def show
  end

  def update
    if @petition.update_attributes(petition_params)
      flash[:notice] = 'Petition has been successfully updated'
      redirect_to [:admin, @petition]
    else
      render :show
    end
  end

  private

  def fetch_petition
    @petition = Petition.find(params[:petition_id])
  end

  def petition_params
    params.require(:petition).permit(:action, :background, :additional_details)
  end
end
