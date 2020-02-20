class Admin::CompletionController < Admin::AdminController
  before_action :fetch_petition

  def update
    if @petition.complete
      redirect_to [:admin, @petition], notice: :petition_updated
    else
      render 'admin/petitions/show'
    end
  end

  private

  def fetch_petition
    @petition = Petition.find(params[:petition_id])
  end
end
