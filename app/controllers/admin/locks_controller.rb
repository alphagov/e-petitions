class Admin::LocksController < Admin::AdminController
  before_action :fetch_petition

  def show
    @petition.update_lock!(current_user)

    respond_to do |format|
      format.json
    end
  end

  def create
    @petition.checkout!(current_user)

    respond_to do |format|
      format.json
    end
  end

  def update
    @petition.force_checkout!(current_user)

    respond_to do |format|
      format.json
    end
  end

  def destroy
    @petition.release!(current_user)

    respond_to do |format|
      format.json
    end
  end

  private

  def last_request_update_allowed?
    false
  end

  def fetch_petition
    @petition = Petition.find(params[:petition_id])
  rescue ActiveRecord::RecordNotFound
    json = {
      error: {
        status: 404,
        message: "Not Found"
      }
    }

    render json: json, status: :not_found
  end
end
