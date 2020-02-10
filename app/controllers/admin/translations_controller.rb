class Admin::TranslationsController < Admin::AdminController
  skip_before_action :verify_authenticity_token
  skip_before_action :require_admin

  before_action :set_cors_headers
  before_action :do_not_cache

  def index
    respond_to do |format|
      format.js
    end
  end

  private

  def set_cors_headers
    if request.origin.in?(Site.urls)
      headers['Access-Control-Allow-Origin']      = request.origin
      headers['Access-Control-Allow-Methods']     = 'GET'
      headers['Access-Control-Allow-Headers']     = 'Origin, X-Requested-With, Content-Type, Accept'
      headers['Access-Control-Allow-Credentials'] = 'true'
      headers['Vary'] = 'Origin'
    else
      raise ActionController::InvalidCrossOriginRequest, "Requests are only allowed from #{Site.urls.inspect}"
    end
  end
end
