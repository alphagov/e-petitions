class Admin::Archived::PetitionEmailsController < Admin::AdminController
  before_action :fetch_petition
  before_action :build_email, only: [:new, :create]
  before_action :fetch_email, only: [:edit, :update, :destroy]

  def new
    render 'admin/archived/petitions/show'
  end

  def create
    if @email.update(email_params)
      if send_email_to_petitioners?
        schedule_email_petitioners_job
        send_preview_email
        message = :email_sent_overnight
      elsif send_preview_email?
        send_preview_email
        message = :preview_email_sent
      else
        message = :petition_email_created
      end

      redirect_to admin_archived_petition_url(@petition), notice: message
    else
      render 'admin/archived/petitions/show'
    end
  end

  def edit
  end

  def update
    if @email.update(email_params)
      if send_email_to_petitioners?
        schedule_email_petitioners_job
        send_preview_email
        message = :email_sent_overnight
      elsif send_preview_email?
        send_preview_email
        message = :preview_email_sent
      else
        message = :petition_email_updated
      end

      redirect_to admin_archived_petition_url(@petition), notice: message
    else
      render 'admin/archived/petitions/show'
    end
  end

  def destroy
    if @email.destroy
      message = :petition_email_deleted
    else
      message = :petition_email_not_deleted
    end

    redirect_to admin_archived_petition_url(@petition), notice: message
  end

  private

  def fetch_petition
    @petition = ::Archived::Petition.published.find(params[:petition_id])
  end

  def build_email
    @email = @petition.emails.build
  end

  def fetch_email
    @email = @petition.emails.find(params[:id])
  end

  def email_params
    params.require(:archived_petition_email).permit(:subject, :body).merge(sent_by: current_user.pretty_name)
  end

  def feedback_signature
    FeedbackSignature.new(@petition)
  end

  def send_email_to_petitioners?
    params.key?(:save_and_email)
  end

  def send_preview_email?
    params.key?(:save_and_preview)
  end

  def schedule_email_petitioners_job
    ::Archived::EmailPetitionersJob.run_later_tonight(petition: @petition, email: @email)
  end

  def send_preview_email
    ::Archived::PetitionMailer.email_signer(@petition, feedback_signature, @email).deliver_now
  end
end
