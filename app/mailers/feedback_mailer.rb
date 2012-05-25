class FeedbackMailer < ActionMailer::Base
  TO = "petitions@example.com"
  default :from => AppConfig.email_from
  layout 'default_mail'

  def send_feedback(feedback)
    @feedback = feedback
    mail :to => TO,
      :subject => "e-petitions: Feedback received",
      'Reply-To' => feedback.email
  end
end
