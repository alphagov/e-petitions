class Admin::ArchiveController < Admin::AdminController
  before_action :fetch_petition

  def update
    if @petition.archive
      redirect_to [:admin, @petition], notice: :petition_updated
    else
      redirect_to [:admin, @petition], alert: :petition_not_updated
    end
  end

  private

  def fetch_petition
    @petition = Petition.find(params[:petition_id])
  end
end
