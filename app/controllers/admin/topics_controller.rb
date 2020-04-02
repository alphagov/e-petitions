class Admin::TopicsController < Admin::AdminController
  before_action :require_sysadmin
  before_action :find_topics, only: [:index]
  before_action :find_topic, only: [:edit, :update, :destroy]
  before_action :build_topic, only: [:new, :create]
  before_action :destroy_topic, only: [:destroy]

  def index
    respond_to do |format|
      format.html
    end
  end

  def new
    respond_to do |format|
      format.html
    end
  end

  def create
    if @topic.save
      redirect_to_index_url notice: :topic_created
    else
      respond_to do |format|
        format.html { render :new }
      end
    end
  end

  def edit
    respond_to do |format|
      format.html
    end
  end

  def update
    if @topic.update(topic_params)
      redirect_to_index_url notice: :topic_updated
    else
      respond_to do |format|
        format.html { render :edit }
      end
    end
  end

  def destroy
    redirect_to_index_url notice: :topic_deleted
  end

  private

  def find_topics
    @topics = Topic.search(params)
  end

  def find_topic
    @topic = Topic.find(params[:id])
  end

  def build_topic
    @topic = Topic.new(topic_params)
  end

  def destroy_topic
    @topic.destroy
  end

  def topic_params
    if params.key?(:topic)
      params.require(:topic).permit(:code, :name)
    else
      {}
    end
  end

  def index_url
    admin_topics_url(params.permit(:q))
  end

  def redirect_to_index_url(options = {})
    redirect_to index_url, options
  end
end
