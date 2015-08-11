class Admin::PetitionEmailsController < Admin::AdminController
  respond_to :html
  before_action :fetch_petition
  before_action :build_email

  def new
    render 'admin/petitions/show'
  end

  def create
    if @email.update(email_params)
      EmailPetitionersJob.run_later_tonight(petition: @petition, email: @email)
      PetitionMailer.email_signer(@petition, feedback_signature, @email).deliver_now

      redirect_to [:admin, @petition], notice: 'Email will be sent overnight'
    else
      render 'admin/petitions/show'
    end
  end

  private

  def fetch_petition
    @petition = Petition.moderated.find(params[:petition_id])
  end

  def build_email
    @email = @petition.emails.build(sent_by: current_user.pretty_name)
  end

  def email_params
    params.require(:petition_email).permit(:subject, :body)
  end

  def feedback_signature
    FeedbackSignature.new(@petition)
  end
end
