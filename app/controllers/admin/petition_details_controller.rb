class Admin::PetitionDetailsController < Admin::AdminController
  before_action :fetch_petition

  def show
  end

  def update
    if @petition.update(petition_params)
      redirect_to [:admin, @petition], notice: :petition_updated
    else
      render :show, alert: :petition_not_saved
    end
  end

  private

  def fetch_petition
    @petition = Petition.find(params[:petition_id])
  end

  def petition_params
    params.require(:petition).permit(
      :action, :background, :additional_details, :committee_note,
      :special_consideration, :do_not_anonymize,
      :creator_attributes => [:name, :email]
    )
  end
end
