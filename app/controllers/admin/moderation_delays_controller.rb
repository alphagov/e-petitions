class Admin::ModerationDelaysController < Admin::AdminController
  before_action :build_moderation_delay

  def new
    respond_to do |format|
      format.html
    end
  end

  def create
    if @moderation_delay.valid?
      save_attributes_to_session
      enqeue_job

      if send_email_to_creators?
        redirect_to admin_petitions_url(state: :overdue_in_moderation), notice: :moderation_delay_sent
      else
        respond_to do |format|
          format.html { render :new, notice: :moderation_delay_preview_sent }
        end
      end
    else
      respond_to do |format|
        format.html { render :new }
      end
    end
  end

  private

  def build_moderation_delay
    @moderation_delay = ModerationDelay.new(moderation_delay_params)
  end

  def moderation_delay_params
    if params.key?(:moderation_delay)
      params.require(:moderation_delay).permit(:subject, :body)
    else
      session[:moderation_delay] || {}
    end
  end

  def save_attributes_to_session
    session[:moderation_delay] = @moderation_delay.attributes
  end

  def send_email_to_creators?
    params.key?(:email_creators)
  end

  def enqeue_job
    if send_email_to_creators?
      job_class = NotifyCreatorsThatModerationIsDelayedJob
      job_args = []
      job_method = :perform_later
    else
      job_class = NotifyCreatorThatModerationIsDelayedJob
      job_args = [feedback_signature]
      job_method = :perform_now
    end

    job_args << @moderation_delay.subject
    job_args << @moderation_delay.body

    job_class.public_send(job_method, *job_args)
  end

  def feedback_signature
    FeedbackSignature.new(example_petition)
  end

  def example_petition
    Petition.overdue_in_moderation.last
  end
end
