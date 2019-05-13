class FeedbackEmailJob < EmailJob
  class SendingDisabledError < RuntimeError; end

  self.mailer = FeedbackMailer
  self.email = :send_feedback

  rescue_from SendingDisabledError do
    reschedule_job
  end

  before_perform if: :feedback_sending_disabled? do
    raise SendingDisabledError, "Feedback sending is currently disabled"
  end

  private

  def reschedule_job(time = 1.hour.from_now)
    self.class.set(wait_until: time).perform_later(*arguments)
  end

  def feedback_sending_disabled?
    Site.disable_feedback_sending?
  end
end
