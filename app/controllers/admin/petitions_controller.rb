class Admin::PetitionsController < Admin::AdminController
  respond_to :html

  def index
    if search_by_tag? && !query.blank?
      petitions_for_individual_tag
    else
      petitions_search
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
      redirect_to admin_petition_url(@petition), notice: :email_sent_overnight
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

  def search_by_tag?
    search_type == "tag"
  end

  def search_type
    @search_type ||= params.fetch(:search_type, "keyword")
  end

  def petitions_search
    @petitions = Petition.search(params.merge(count: 50))
    @query = query
    @state = state
    @tag_filters = tag_filters
  end

  def petitions_for_individual_tag
    @petitions = Petition.tagged_with(query).search(
      page: params[:page],
      per_page: 50,
      search_type: search_type,
      state: state,
      tag_filters: tag_filters
    )

    @query = query
    @state = state
    @tag_filters = tag_filters
  end

  def query
    @query ||= params.fetch(:q, '')
  end

  def state
    @state ||= params.fetch(:state, :all)
  end

  def tag_filters
    @tag_filters ||= params.fetch(:tag_filters, [])
  end

  def fetch_petition_for_scheduled_debate_date
    @petition = Petition.find(params[:id])
    raise ActiveRecord::RecordNotFound unless @petition.can_have_debate_added?
  end

  def update_scheduled_debate_date_params
    params.require(:petition).permit(:scheduled_debate_date)
  end
end
