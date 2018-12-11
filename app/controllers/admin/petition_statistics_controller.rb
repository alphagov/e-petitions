class Admin::PetitionStatisticsController < Admin::AdminController
  before_action :require_sysadmin
  before_action :fetch_petition

  def update
    UpdatePetitionStatisticsJob.perform_later(@petition)
    redirect_to admin_petition_url(@petition), notice: :enqueued_petition_statistics_update
  end

  private

  def fetch_petition
    @petition = Petition.moderated.find(params[:petition_id])
  end
end
