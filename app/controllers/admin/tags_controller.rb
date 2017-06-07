class Admin::TagsController < Admin::AdminController
  respond_to :html
  before_action :fetch_petition
  before_action :find_site_settings

  def show
    render 'admin/petitions/show'
  end

  def update
    if @petition.update(params_for_update)
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
    params.require(:petition).permit(tags: [])
  end

  def find_site_settings
    @site_settings ||= Admin::Site.first_or_create!
  end
end
