class Admin::Archived::PetitionTopicsController < Admin::AdminController
  before_action :fetch_petition

  def show
    render 'admin/archived/petitions/show'
  end

  def update
    if @petition.update(petition_params)
      redirect_to admin_archived_petition_url(@petition), notice: :petition_updated
    else
      render 'admin/archived/petitions/show', alert: :petition_not_updated
    end
  end

  private

  def fetch_petition
    @petition = ::Archived::Petition.find(params[:petition_id])
  end

  def petition_params
    params.require(:petition).permit(topics: [])
  end
end
