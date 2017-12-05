require 'csv'

class Admin::StatisticsController < Admin::AdminController
  after_action :set_content_disposition, if: :csv_request?, except: [:index]

  def index
    respond_to do |format|
      format.html
    end
  end

  def moderation
    @rows = Statistics.moderation(by: period, parliament: parliament)

    respond_to do |format|
      format.csv
    end
  end

  private

  def parliament
    if params.key?(:parliament)
      Parliament.find(params[:parliament])
    end
  end

  def period
    params[:period]
  end

  def csv_filename
    if params.key?(:parliament)
      "#{action_name}-#{parliament.period}-by-#{period}.csv"
    else
      "#{action_name}-by-#{period}.csv"
    end
  end

  def set_content_disposition
    response.headers['Content-Disposition'] = "attachment; filename=#{csv_filename}"
  end
end
