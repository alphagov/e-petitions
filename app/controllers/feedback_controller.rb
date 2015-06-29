class FeedbackController < ApplicationController
  respond_to :html

  def index
    respond_with @feedback = Feedback.new
  end

  # TODO: We should use deliver_later but serializing the feedback model is tricky.
  def create
    @feedback = Feedback.new(params[:feedback])
    if @feedback.valid?
      FeedbackMailer.send_feedback(@feedback).deliver_now
      redirect_to thanks_feedback_url
    else
      render 'index'
    end
  end

  def thanks
  end
end
