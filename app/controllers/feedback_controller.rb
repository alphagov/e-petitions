class FeedbackController < PublicController
  before_action :build_feedback, only: [:new, :create]

  rescue_from Feedback::RateLimitExceededError do
    redirect_to thanks_feedback_url
  end

  def new
    respond_to do |format|
      format.html
    end
  end

  def create
    if @feedback.save
      FeedbackEmailJob.perform_later(@feedback)
      redirect_to thanks_feedback_url
    else
      respond_to do |format|
        format.html { render :new }
      end
    end
  end

  def thanks
    respond_to do |format|
      format.html
    end
  end

  private

  def build_feedback
    @feedback = Feedback.new(params.key?(:feedback) ? feedback_params : {})
  end

  def feedback_params
    params.require(:feedback).permit(*feedback_attributes).merge(additional_params)
  end

  def feedback_attributes
    [:email, :petition_link_or_title, :comment]
  end

  def additional_params
    {
      user_agent: request.user_agent,
      ip_address: request.remote_ip
    }
  end
end
