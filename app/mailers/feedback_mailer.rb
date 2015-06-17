class FeedbackMailer < ApplicationMailer
  TO = "petitions@example.com"

  def send_feedback(feedback)
    @feedback = feedback
    mail :to => TO,
      :subject => "Feedback from the Petitions service",
      'Reply-To' => feedback.email
  end
end
