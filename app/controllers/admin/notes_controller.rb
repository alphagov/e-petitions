class Admin::NotesController < Admin::AdminController
  respond_to :html
  before_action :fetch_petition

  def show
    render 'admin/petitions/show'
  end

  def update
    if @petition.update_attributes(params_for_update)
      redirect_to [:admin, @petition]
    else
      render 'admin/petitions/show'
    end
  end

  private
  def fetch_petition
    @petition = Petition.find(params[:petition_id])
  end

  def params_for_update
    params.
      require(:petition).
      permit(:admin_notes)
  end
end
