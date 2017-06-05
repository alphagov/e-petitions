class Admin::SiteController < Admin::AdminController
  before_action :require_sysadmin
  before_action :find_site_settings

  def edit
    respond_to do |format|
      format.html
    end
  end

  def update
    if @site_settings.update(site_params)
      redirect_to edit_admin_site_url, notice: :site_settings_updated
    else
      respond_to do |format|
        format.html { render :edit }
      end
    end
  end

  private

  def site_params
    params.require(:admin_site).permit(*site_attributes)
  end

  def site_attributes
    %i[
      petition_tags
    ]
  end

  def find_site_settings
    @site_settings = Admin::Site.first_or_create!
  end
end
