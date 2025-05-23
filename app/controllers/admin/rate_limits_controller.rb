class Admin::RateLimitsController < Admin::AdminController
  before_action :require_sysadmin
  before_action :find_rate_limit

  def edit
    respond_to do |format|
      format.html
    end
  end

  def update
    if @rate_limit.update(rate_limit_params)
      redirect_to edit_admin_rate_limits_url(tab: params[:tab]), notice: :rate_limits_updated
    else
      respond_to do |format|
        format.html { render :edit }
      end
    end
  end

  private

  def rate_limit_params
    params.require(:rate_limit).permit(*rate_limit_attributes)
  end

  def rate_limit_attributes
    %i[
      burst_rate burst_period sustained_rate sustained_period creator_rate
      sponsor_rate feedback_rate allowed_domains allowed_ips blocked_domains blocked_ips
      geoblocking_enabled countries country_rate_limits_enabled
      country_burst_rate country_sustained_rate trending_items_notification_url
      threshold_for_logging_trending_items threshold_for_notifying_trending_items
      enable_logging_of_trending_items ignored_domains blocked_emails
    ]
  end

  def find_rate_limit
    @rate_limit = RateLimit.first_or_create!
  end
end
