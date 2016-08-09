class Admin::InvalidationsController < Admin::AdminController
  before_action :require_sysadmin
  before_action :build_invalidation, only: [:new, :create]
  before_action :find_invalidation, only: [:edit, :update, :destroy, :count, :cancel, :start]
  before_action :find_invalidations, only: [:index]

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
    if @invalidation.save
      redirect_to admin_invalidations_url, notice: :invalidation_created
    else
      respond_to do |format|
        format.html { render :new }
      end
    end
  end

  def edit
    if @invalidation.pending?
      respond_to do |format|
        format.html
      end
    else
      redirect_to_index_url notice: :invalidation_cant_be_edited
    end
  end

  def update
    if @invalidation.pending?
      if @invalidation.update(invalidation_params)
        redirect_to admin_invalidations_url, notice: :invalidation_updated
      else
        respond_to do |format|
          format.html { render :edit }
        end
      end
    else
      redirect_to_index_url notice: :invalidation_cant_be_edited
    end
  end

  def destroy
    if @invalidation.started?
      redirect_to_index_url notice: :invalidation_cant_be_removed
    else
      if @invalidation.destroy
        redirect_to_index_url notice: :invalidation_removed
      else
        redirect_to_index_url alert: :invalidation_not_removed
      end
    end
  end

  def cancel
    if @invalidation.completed?
      redirect_to_index_url notice: :invalidation_cant_be_cancelled
    else
      if @invalidation.cancel!
        redirect_to_index_url notice: :invalidation_cancelled
      else
        redirect_to_index_url alert: :invalidation_not_cancelled
      end
    end
  end

  def count
    if @invalidation.pending?
      if @invalidation.count!
        redirect_to_index_url notice: [:invalidation_counted, summary: @invalidation.summary.inspect]
      else
        redirect_to_index_url alert: :invalidation_not_counted
      end
    else
      redirect_to_index_url notice: :invalidation_cant_be_counted
    end
  end

  def start
    if @invalidation.pending?
      if @invalidation.start!
        redirect_to_index_url notice: [:invalidation_started, summary: @invalidation.summary.inspect]
      else
        redirect_to_index_url alert: :invalidation_not_started
      end
    else
      redirect_to_index_url notice: :invalidation_cant_be_started
    end
  end

  private

  def invalidation_params
    if params.key?(:invalidation)
      params.require(:invalidation).permit(*invalidation_attributes)
    else
      {}
    end
  end

  def invalidation_attributes
    %i[summary details] + Invalidation::CONDITIONS
  end

  def build_invalidation
    @invalidation = Invalidation.new(invalidation_params)
  end

  def find_invalidation
    @invalidation = Invalidation.find(params[:id])
  end

  def find_invalidations
    @invalidations = Invalidation.search(params)
  end

  def index_url
    admin_invalidations_url(params.slice(:state, :q))
  end

  def redirect_to_index_url(options = {})
    redirect_to index_url, options
  end
end
