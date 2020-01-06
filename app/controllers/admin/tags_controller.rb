class Admin::TagsController < Admin::AdminController
  before_action :require_sysadmin
  before_action :find_tags, only: [:index]
  before_action :find_tag, only: [:edit, :update, :destroy]
  before_action :build_tag, only: [:new, :create]
  before_action :destroy_tag, only: [:destroy]

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
    if @tag.save
      redirect_to_index_url notice: :tag_created
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
    if @tag.update(tag_params)
      redirect_to_index_url notice: :tag_updated
    else
      respond_to do |format|
        format.html { render :edit }
      end
    end
  end

  def destroy
    redirect_to_index_url notice: :tag_deleted
  end

  private

  def find_tags
    @tags = Tag.search(params)
  end

  def find_tag
    @tag = Tag.find(params[:id])
  end

  def build_tag
    @tag = Tag.new(tag_params)
  end

  def destroy_tag
    @tag.destroy
  end

  def tag_params
    if params.key?(:tag)
      params.require(:tag).permit(:name, :description)
    else
      {}
    end
  end

  def index_url
    admin_tags_url(params.permit(:q))
  end

  def redirect_to_index_url(options = {})
    redirect_to index_url, options
  end
end
