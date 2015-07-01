class Admin::TakeDownController < Admin::AdminController
  before_action :fetch_petition
  respond_to :html

  def show
    render 'admin/petitions/show'
  end

  def update
    if @petition.reject(rejection_params)
      PetitionMailer.petition_rejected(@petition).deliver_now
      redirect_to [:admin, @petition]
    else
      @petition.state = @petition.state_was
      render 'admin/petitions/show'
    end
  end

  private
  def fetch_petition
    @petition = Petition.find(params[:petition_id])
  end

  def rejection_params
    params.require(:petition).permit(:rejection_code, :rejection_text)
  end

end
