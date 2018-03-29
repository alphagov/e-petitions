class Admin::HolidaysController < Admin::AdminController
  before_action :require_sysadmin
  before_action :fetch_holiday

  def edit
    respond_to do |format|
      format.html
    end
  end

  def update
    if @holiday.update(holiday_params)
      redirect_to edit_admin_site_url, notice: :site_updated
    else
      respond_to do |format|
        format.html { render :edit }
      end
    end
  end

  private

  def fetch_holiday
    @holiday = Holiday.instance
  end

  def holiday_params
    params.require(:holiday).permit(*holiday_attributes)
  end

  def holiday_attributes
    %i[christmas_start christmas_end easter_start easter_end]
  end
end
