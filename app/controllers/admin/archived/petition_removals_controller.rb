class Admin::Archived::PetitionRemovalsController < Admin::AdminController
  before_action :require_sysadmin
  before_action :fetch_petition
  before_action :redirect_to_petition_page, if: :already_removed?

  def show
    render 'admin/archived/petitions/show'
  end

  def update
    if @petition.remove(petition_params)
      redirect_to admin_archived_petition_url(@petition), notice: :petition_updated
    else
      render 'admin/archived/petitions/show', alert: :petition_not_saved
    end
  end

  private

  def fetch_petition
    @petition = Archived::Petition.find(params[:petition_id])
  end

  def petition_params
    params.require(:archived_petition).permit(:reason_for_removal)
  end

  def already_removed?
    @petition.removed?
  end

  def redirect_to_petition_page
    redirect_to admin_archived_petition_url(@petition), notice: :petition_already_removed
  end
end
