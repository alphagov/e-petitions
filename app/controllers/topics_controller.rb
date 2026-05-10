class TopicsController < PublicController
  before_action :fetch_topics
  before_action :set_cors_headers

  def index
    fresh_when(
      last_modified: @topics.last_modified_at,
      cache_control: @topics.cache_control,
      public: true
    )

    respond_to do |format|
      format.json
    end
  end

  private

  def fetch_topics
    @topics = Topic.by_name
  end
end
