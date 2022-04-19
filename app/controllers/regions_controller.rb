class RegionsController < LocalizedController
  before_action :set_cors_headers, only: [:index], if: :json_request?

  skip_forgery_protection

  def index
    @regions = Region.all

    respond_to do |format|
      format.json
      format.geojson
      format.js
    end
  end
end
