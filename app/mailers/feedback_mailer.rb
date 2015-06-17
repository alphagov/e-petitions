class FeedbackMailer < ApplicationMailer
  def send_feedback(feedback)
    @feedback = feedback

    mail  to: Site.feedback_email,
          subject: "Feedback from the Petitions service",
          reply_to: feedback.email
  end
end
