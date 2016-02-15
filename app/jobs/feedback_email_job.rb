class FeedbackEmailJob < EmailJob
  self.mailer = FeedbackMailer
  self.email = :send_feedback
end
