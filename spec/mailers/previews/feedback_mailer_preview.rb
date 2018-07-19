# Preview all emails at http://localhost:3000/rails/mailers/feedback_mailer
class FeedbackMailerPreview < ActionMailer::Preview
  def send_feedback
    FeedbackMailer.send_feedback(Feedback.last)
  end
end
