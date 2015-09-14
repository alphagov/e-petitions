class FeedbackController < ApplicationController
  respond_to :html

  def index
    respond_with @feedback = Feedback.new
  end

  # TODO: We should use deliver_later but serializing the feedback model is tricky.
  def create
    @feedback = Feedback.new(feedback_params)
    if @feedback.valid?
      FeedbackMailer.send_feedback(@feedback).deliver_now
      redirect_to thanks_feedback_url
    else
      render 'index'
    end
  end

  def thanks
  end

  private

  def feedback_params
    params.require(:feedback).permit(*feedback_attributes).merge(user_agent)
  end

  def feedback_attributes
    [:email, :petition_link_or_title, :comment]
  end

  def user_agent
    { user_agent: request.user_agent }
  end
end
