class Admin::TakeDownController < Admin::AdminController
  before_action :fetch_petition
  respond_to :html

  def show
  end

  def update
    if @petition.reject(rejection_params)
      PetitionMailer.petition_rejected(@petition).deliver_now
      redirect_to [:admin, @petition]
    else
      render 'show'
    end
  end

  private
  def fetch_petition
    @petition = Petition.for_state(Petition::OPEN_STATE).find(params[:petition_id])
  end

  def rejection_params
    params.require(:petition).permit(:rejection_code, :rejection_text)
  end

end
