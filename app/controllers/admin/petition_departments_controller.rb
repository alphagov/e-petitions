class Admin::PetitionDepartmentsController < Admin::AdminController
  before_action :fetch_petition

  def show
    render 'admin/petitions/show'
  end

  def update
    if @petition.update(petition_params)
      respond_to do |format|
        format.html { redirect_to admin_petition_url(@petition), notice: :petition_updated }
        format.json { render json: { updated: true } }
      end
    else
      respond_to do |format|
        format.html { render 'admin/petitions/show', alert: :petition_not_updated }
        format.json { render json: { updated: false } }
      end
    end
  end

  private

  def fetch_petition
    @petition = Petition.find(params[:petition_id])
  end

  def petition_params
    params.require(:petition).permit(departments: [])
  end
end
