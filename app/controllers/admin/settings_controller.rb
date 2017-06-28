class Admin::SettingsController < Admin::AdminController
  before_action :require_sysadmin

  def edit
    respond_to do |format|
      format.html
    end
  end

  def update
    if @admin_settings.update(site_params)
      redirect_to edit_admin_settings_url, notice: :admin_settings_updated
    else
      respond_to do |format|
        format.html { render :edit }
      end
    end
  end

  private

  def site_params
    params.require(:admin_settings).permit(*site_attributes)
  end

  def site_attributes
    %i[
      petition_tags
    ]
  end
end
