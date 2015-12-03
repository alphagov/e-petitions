class Admin::PetitionEmailsController < Admin::AdminController
  respond_to :html
  before_action :fetch_petition
  before_action :build_email, only: [:new, :create]
  before_action :fetch_email, only: [:edit, :update, :destroy]

  def new
    render 'admin/petitions/show'
  end

  def create
    if @email.update(email_params)
      if send_email_to_petitioners?
        schedule_email_petitioners_job
        message = 'Email will be sent overnight'
      else
        message = 'Created other parliamentary business successfully'
      end

      redirect_to [:admin, @petition], notice: message
    else
      render 'admin/petitions/show'
    end
  end

  def edit
  end

  def update
    if @email.update(email_params)
      if send_email_to_petitioners?
        schedule_email_petitioners_job
        message = 'Email will be sent overnight'
      else
        message = 'Updated other parliamentary business successfully'
      end

      redirect_to [:admin, @petition], notice: message
    else
      render 'admin/petitions/show'
    end
  end

  def destroy
    if @email.destroy
      message = 'Deleted other parliamentary business successfully'
    else
      message = 'Unable to delete other parliamentary business - please contact support'
    end

    redirect_to [:admin, @petition], notice: message
  end

  private

  def fetch_petition
    @petition = Petition.moderated.find(params[:petition_id])
  end

  def build_email
    @email = @petition.emails.build
  end

  def fetch_email
    @email = @petition.emails.find(params[:id])
  end

  def email_params
    params.require(:petition_email).permit(:subject, :body).merge(sent_by: current_user.pretty_name)
  end

  def feedback_signature
    FeedbackSignature.new(@petition)
  end

  def send_email_to_petitioners?
    params.key?(:save_and_email)
  end

  def schedule_email_petitioners_job
    EmailPetitionersJob.run_later_tonight(petition: @petition, email: @email)
    PetitionMailer.email_signer(@petition, feedback_signature, @email).deliver_now
  end
end
