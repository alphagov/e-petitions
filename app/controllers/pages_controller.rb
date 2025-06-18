class PagesController < ApplicationController
  before_action :retrieve_page, only: :show
  before_action :respond_if_fresh, only: :show
  before_action :set_cors_headers, only: :trending, if: :json_request?

  def index
    respond_to do |format|
      format.html
    end
  end

  def show
    respond_to do |format|
      format.html do
        if @page.redirect?
          redirect_to @page.redirect_url, allow_other_host: true
        else
          render :show
        end
      end
    end
  end

  def trending
    respond_to do |format|
      format.json
    end
  end

  def browserconfig
    expires_in 1.hour, public: true

    respond_to do |format|
      format.xml
    end
  end

  def manifest
    expires_in 1.hour, public: true

    respond_to do |format|
      format.json
    end
  end

  private

  def retrieve_page
    @page = Page.find_by!(slug: params[:slug], enabled: true)
  end

  def respond_if_fresh
    fresh_when @page, public: true
  end
end
