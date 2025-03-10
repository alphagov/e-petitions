class Admin::Email::SettingsController < Admin::AdminController
  before_action :require_sysadmin
  before_action :find_site

  def show
    respond_to do |format|
      format.html
    end
  end

  def update
    if @site.update(site_params)
      redirect_to admin_email_settings_url, notice: :email_settings_updated
    else
      respond_to do |format|
        format.html { render :show }
      end
    end
  end

  private

  def find_site
    @site = Site.instance
  end

  def site_params
    params.require(:site).permit(:enhanced_email_formatting, :email_header_style)
  end
end
