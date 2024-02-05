class Admin::Archived::PetitionTagsController < Admin::AdminController
  before_action :fetch_petition

  def show
    render 'admin/archived/petitions/show'
  end

  def update
    if @petition.update(petition_params)
      respond_to do |format|
        format.html { redirect_to admin_archived_petition_url(@petition), notice: :petition_updated }
        format.json { render json: { updated: true } }
      end
    else
      respond_to do |format|
        format.html { render 'admin/archived/petitions/show', alert: :petition_not_updated }
        format.json { render json: { updated: true } }
      end
    end
  end

  private

  def fetch_petition
    @petition = ::Archived::Petition.find(params[:petition_id])
  end

  def petition_params
    params.require(:petition).permit(tags: [])
  end
end
