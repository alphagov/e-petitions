class RegionsController < LocalizedController
  before_action :set_cors_headers, only: [:index], if: :json_request?

  def index
    @regions = Region.all

    respond_to do |format|
      format.json
    end
  end
end
