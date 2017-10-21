class Admin::Archived::PetitionsController < Admin::AdminController
  before_action :redirect_to_show_page, only: [:index], if: :petition_id?
  before_action :fetch_parliament, only: [:index]
  before_action :fetch_petitions, only: [:index]
  before_action :fetch_petition, only: [:show]

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

  protected

  def petition_id?
    /^\d+$/ =~ params[:q].to_s
  end

  def redirect_to_show_page
    redirect_to admin_archived_petition_url(params[:q].to_i)
  end

  def scope
    if params[:match] == "none"
      @parliament.petitions.untagged
    elsif params[:tags].present?
      if params[:match] == "all"
        @parliament.petitions.tagged_with_all(params[:tags])
      else
        @parliament.petitions.tagged_with_any(params[:tags])
      end
    else
      @parliament.petitions.all
    end
  end

  def parliament_id
    params[:parliament].to_i
  end

  def fetch_parliament
    if params.key?(:parliament)
      @parliament = Parliament.archived.find(parliament_id)
    else
      @parliament = Parliament.archived.first
    end
  end

  def fetch_petitions
    @petitions = scope.search(params)
  end

  def fetch_petition
    @petition = ::Archived::Petition.find(params[:id])
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
    #nginx doc: Setting this to "no" will allow unbuffered responses suitable for Comet and HTTP streaming applications
    headers['X-Accel-Buffering'] = 'no'
    headers["Cache-Control"] ||= "no-cache"
    headers.delete("Content-Length")
  end

  def csv_filename
    "#{@petitions.scope.to_s.dasherize}-petitions-#{Time.current.to_s(:number)}.csv"
  end
end
