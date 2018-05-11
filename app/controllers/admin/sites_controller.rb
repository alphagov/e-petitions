class Admin::SitesController < Admin::AdminController
  before_action :require_sysadmin
  before_action :fetch_site

  def edit
    respond_to do |format|
      format.html
    end
  end

  def update
    if @site.update(site_params)
      redirect_to edit_admin_site_url, notice: :site_updated
    else
      respond_to do |format|
        format.html { render :edit }
      end
    end
  end

  private

  def fetch_site
    @site = Site.instance
  end

  def site_params
    params.require(:site).permit(
      :title, :url, :email_from, :username, :password, :enabled,
      :protected, :petition_duration, :minimum_number_of_sponsors,
      :maximum_number_of_sponsors, :threshold_for_moderation,
      :threshold_for_response, :threshold_for_debate, :feedback_email,
      :moderate_url, :login_timeout, :disable_constituency_api
    )
  end
end
