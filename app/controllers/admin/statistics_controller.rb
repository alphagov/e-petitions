require 'csv'

class Admin::StatisticsController < Admin::AdminController
  before_action :set_form

  def index
    respond_to do |format|
      format.html
    end
  end

  def create
    if @form.save
      redirect_to_index_url notice: :report_request_submitted
    else
      respond_to do |format|
        format.html { render :index }
      end
    end
  end

  private

  def tab_param
    case params[:tab]
    when 'signature_counts'
      'signature_counts'
    else
      'moderation_performance'
    end
  end

  def set_form
    @form = Statistics[tab_param].build(params)
  end

  def index_url
    admin_stats_url(tab: @form.tab)
  end

  def redirect_to_index_url(options = {})
    redirect_to index_url, options
  end
end
