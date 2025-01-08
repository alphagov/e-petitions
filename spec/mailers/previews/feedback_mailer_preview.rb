# Preview all emails at http://petitions.localhost:3000/rails/mailers/feedback_mailer
class FeedbackMailerPreview < ActionMailer::Preview
  def send_feedback
    FeedbackMailer.send_feedback(Feedback.last)
  end
end
