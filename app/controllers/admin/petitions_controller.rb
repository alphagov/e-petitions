class Admin::PetitionsController < Admin::AdminController
  before_action :redirect_to_show_page, only: [:index], if: :petition_id?
  before_action :fetch_petitions, only: [:index]
  before_action :fetch_petition, only: [:show, :resend]

  after_action :set_back_location, only: [:index]

  rescue_from ActiveRecord::RecordNotFound do
    redirect_to admin_root_url, alert: "Sorry, we couldn't find petition #{params[:id]}"
  end

  def index
    respond_to do |format|
      format.html
      format.csv { render_csv }
    end
  end

  def show
    respond_to do |format|
      format.html
    end
  end

  def resend
    GatherSponsorsForPetitionEmailJob.perform_later(@petition, Site.feedback_email)
    redirect_to admin_petition_url(@petition), notice: :email_resent_to_creator
  end

  protected

  def petition_id?
    /^\d+$/ =~ params[:q].to_s
  end

  def redirect_to_show_page
    redirect_to admin_petition_url(params[:q].to_i)
  end

  def tag_scope(current)
    if params[:match] == "none"
      current.untagged
    elsif params[:tags].present?
      if params[:match] == "all"
        current.tagged_with_all(params[:tags])
      else
        current.tagged_with_any(params[:tags])
      end
    else
      current
    end
  end

  def preload_scope(current)
    current.preload(:creator, :rejection, :debate_outcome, :note)
  end

  def scope
    preload_scope(tag_scope(Petition.all))
  end

  def fetch_petitions
    @petitions = scope.search(params)
  end

  def fetch_petition
    @petition = Petition.find(params[:id])
  end

  def set_back_location
    session[:back_location] = request.original_fullpath
  end

  def render_csv
    set_file_headers
    set_streaming_headers

    #setting the body to an enumerator, rails will iterate this enumerator
    self.response_body = PetitionsCSVPresenter.new(@petitions).render
  end

  def set_file_headers
    headers["Content-Type"] = "text/csv"
    headers["Content-Disposition"] = "attachment; filename=#{csv_filename}"
  end

  def set_streaming_headers
    headers["X-Accel-Buffering"] = "no"
    headers["Cache-Control"] ||= "no-cache"
    headers["Last-Modified"] = Time.current.httpdate
    headers.delete("Content-Length")
  end

  def csv_filename
    "#{@petitions.scope.to_s.dasherize}-petitions-#{Time.current.to_s(:number)}.csv"
  end
end
