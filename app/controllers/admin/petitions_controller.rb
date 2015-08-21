class Admin::PetitionsController < Admin::AdminController
  respond_to :html

  def index
    if filter_by_tag?
      petitions_by_tag
    else
      petitions_by_filter_or_keyword_search
    end

    respond_to do |format|
      format.html
      format.csv { render_csv }
    end
  end

  def show
    @petition = Petition.find(params[:id])
  end

  def edit_scheduled_debate_date
    fetch_petition_for_scheduled_debate_date
  end

  def update_scheduled_debate_date
    fetch_petition_for_scheduled_debate_date
    if @petition.update(update_scheduled_debate_date_params)
      EmailDebateScheduledJob.run_later_tonight(petition: @petition)
      redirect_to admin_petition_url(@petition), notice: "Email will be sent overnight"
    else
      render :edit_scheduled_debate_date
    end
  end

  protected

  def render_csv
    set_file_headers
    set_streaming_headers

    #setting the body to an enumerator, rails will iterate this enumerator
    self.response_body = PetitionsCSVPresenter.new(@petitions).render
  end

  def set_file_headers
    headers["Content-Type"] = "text/csv"
    headers["Content-disposition"] = "attachment; filename=#{csv_filename}"
  end

  def set_streaming_headers
    #nginx doc: Setting this to "no" will allow unbuffered responses suitable for Comet and HTTP streaming applications
    headers['X-Accel-Buffering'] = 'no'

    headers["Cache-Control"] ||= "no-cache"
    headers.delete("Content-Length")
  end

  def csv_filename
    "#{@petitions.scope.to_s.dasherize}-petitions-#{Time.current.to_s(:number)}.csv"
  end

  def filter_by_tag?
    params[:t].present? && !(filter_by_state? || filter_by_keyword?)
  end

  def filter_by_state?
    params[:state].present?
  end

  def filter_by_keyword?
    params[:q].present?
  end

  def petitions_by_filter_or_keyword_search
    @petitions = Petition.search(params.merge(count: 50))
    @query = params[:q]
  end

  def petitions_by_tag
    @petitions = Petition.tagged_with(params[:t]).paginate(page: params[:page], per_page: 50)
    @query = Petition.sanitized_tag(params[:t])
  end

  def fetch_petition_for_scheduled_debate_date
    @petition = Petition.find(params[:id])
    raise ActiveRecord::RecordNotFound unless @petition.can_have_debate_added?
  end

  def update_scheduled_debate_date_params
    params.require(:petition).permit(:scheduled_debate_date)
  end
end
