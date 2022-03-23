class ConstituenciesController < LocalizedController
  before_action :set_cors_headers, only: [:index], if: :json_request?

  skip_forgery_protection

  def index
    @constituencies = Constituency.all

    respond_to do |format|
      format.json
      format.geojson
      format.js
    end
  end
end
