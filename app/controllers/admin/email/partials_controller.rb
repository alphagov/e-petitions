class Admin::Email::PartialsController < Admin::AdminController
  before_action :require_sysadmin
  before_action :find_partials, only: [:index]
  before_action :find_partial, only: [:edit, :update, :destroy]
  before_action :build_partial, only: [:new, :create]
  before_action :destroy_partial, only: [:destroy]

  def index
    respond_to do |format|
      format.html
      format.yaml
    end
  end

  def new
    respond_to do |format|
      format.html
    end
  end

  def create
    if @partial.save
      redirect_to_index_url notice: :email_partial_created
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
    if @partial.update(partial_params)
      redirect_to_index_url notice: :email_partial_updated
    else
      respond_to do |format|
        format.html { render :edit }
      end
    end
  end

  def destroy
    redirect_to_index_url notice: :email_partial_deleted
  end

  private

  def find_partials
    @partials = Email::Partial.search(params)
  end

  def find_partial
    @partial = Email::Partial.find(params[:id])
  end

  def build_partial
    @partial = Email::Partial.new(partial_params)
  end

  def destroy_partial
    @partial.destroy
  end

  def partial_params
    if params.key?(:partial)
      params.require(:partial).permit(:name, :content)
    else
      {}
    end
  end

  def index_url
    admin_email_partials_url
  end

  def redirect_to_index_url(options = {})
    redirect_to index_url, options
  end
end
