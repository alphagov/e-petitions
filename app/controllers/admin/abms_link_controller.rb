class Admin::AbmsLinkController < Admin::AdminController
  before_action :fetch_petition

  def show
    render 'admin/petitions/show'
  end

  def update
    if @petition.update(petition_params)
      redirect_to [:admin, @petition], notice: :petition_updated
    else
      render 'admin/petitions/show'
    end
  end

  private

  def fetch_petition
    @petition = Petition.find(params[:petition_id])
  end

  def petition_params
    params.require(:petition).permit(:abms_link_en, :abms_link_cy)
  end
end
