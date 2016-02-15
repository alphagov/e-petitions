class FeedbackController < ApplicationController
  respond_to :html

  before_action :build_feedback, only: [:new, :create]

  def index
    respond_with @feedback
  end

  def create
    if @feedback.save
      FeedbackEmailJob.perform_later(@feedback)
    end

    respond_with @feedback, location: thanks_feedback_url
  end

  def thanks
  end

  private

  def build_feedback
    @feedback = Feedback.new(params.key?(:feedback) ? feedback_params : {})
  end

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
