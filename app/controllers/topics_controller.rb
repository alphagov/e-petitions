class TopicsController < PublicController
  before_action :set_cors_headers, only: [:index], if: :json_request?

  def index
    @topics = Topic.by_name

    respond_to do |format|
      format.json
    end
  end
end
