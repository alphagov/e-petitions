class FeedbackMailer < ApplicationMailer
  TO = "petitions@example.com"

  def send_feedback(feedback)
    @feedback = feedback
    mail :to => TO,
      :subject => "e-petitions: Feedback received",
      'Reply-To' => feedback.email
  end
end
