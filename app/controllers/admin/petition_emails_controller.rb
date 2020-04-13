class Admin::PetitionEmailsController < Admin::AdminController
  before_action :fetch_petition
  before_action :build_email, only: [:new, :create]
  before_action :fetch_email, only: [:edit, :update, :destroy]

  def index
    render 'admin/petitions/show'
  end

  def new
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

      redirect_to [:admin, @petition, :emails], notice: message
    else
      render :new
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

      redirect_to [:admin, @petition, :emails], notice: message
    else
      render :edit
    end
  end

  def destroy
    if @email.destroy
      message = :petition_email_deleted
    else
      message = :petition_email_not_deleted
    end

    redirect_to [:admin, @petition, :emails], notice: message
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
    params.require(:petition_email).permit(*email_attributes).merge(sent_by: current_user.pretty_name)
  end

  def email_attributes
    %i[subject_en subject_cy body_en body_cy]
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
    EmailPetitionersJob.run_later_tonight(petition: @petition, email: @email)
  end

  def send_preview_email
    EmailSignerAboutOtherBusinessEmailJob.perform_later(feedback_signature, @email)
  end
end
