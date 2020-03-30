class Admin::RejectionReasonsController < Admin::AdminController
  before_action :require_sysadmin
  before_action :fetch_rejection_reasons
  before_action :build_rejection_reason, only: %i[new create]
  before_action :find_rejection_reason, only: %i[edit update destroy]

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
    if @rejection_reason.save
      redirect_to admin_rejection_reasons_url, notice: :rejection_reason_created
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
    if @rejection_reason.update(rejection_reason_params)
      redirect_to admin_rejection_reasons_url, notice: :rejection_reason_updated
    else
      respond_to do |format|
        format.html { render :edit }
      end
    end
  end

  def destroy
    if @rejection_reason.destroy
      redirect_to admin_rejection_reasons_url, notice: :rejection_reason_deleted
    else
      redirect_to admin_rejection_reasons_url, alert: :rejection_reason_not_deleted
    end
  end

  private

  def fetch_rejection_reasons
    @rejection_reasons = RejectionReason.all.paginate(page: params[:page], per_page: 25)
  end

  def find_rejection_reason
    @rejection_reason = RejectionReason.find(params[:id])
  end

  def build_rejection_reason
    @rejection_reason = RejectionReason.new(rejection_reason_params)
  end

  def rejection_reason_params
    if params.key?(:rejection_reason)
      params.require(:rejection_reason).permit(*rejection_reason_attributes)
    else
      {}
    end
  end

  def rejection_reason_attributes
    %i[code title description_en description_cy hidden]
  end
end
