class PagesController < PublicController
  before_action :retrieve_page, only: :show
  before_action :set_cors_headers, only: :trending, if: :json_request?

  def index
    fresh_when(
      last_modified: Site.last_modified_at,
      cache_control: Site.cache_control,
      public: true
    )

    respond_to do |format|
      format.html
    end
  end

  def show
    if @page.redirect?
      redirect_to @page.redirect_url, allow_other_host: true
    else
      fresh_when(
        last_modified: @page.last_modified_at,
        cache_control: @page.cache_control,
        public: true
      )

      respond_to do |format|
        format.html
      end
    end
  end

  def trending
    fresh_when(
      last_modified: Site.last_modified_at,
      cache_control: Site.cache_control,
      public: true
    )

    respond_to do |format|
      format.json
    end
  end

  def manifest
    fresh_when(
      last_modified: Site.package_built_at,
      cache_control: Site.cache_control(max_age: 5.minutes),
      public: true
    )

    respond_to do |format|
      format.json
    end
  end

  private

  def retrieve_page
    @page = Page.find_by!(slug: params[:slug], enabled: true)
  end
end
