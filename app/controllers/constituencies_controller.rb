class ConstituenciesController < LocalizedController
  before_action :set_cors_headers, only: [:index], if: :json_request?

  def index
    @constituencies = Constituency.all

    respond_to do |format|
      format.json
    end
  end
end
