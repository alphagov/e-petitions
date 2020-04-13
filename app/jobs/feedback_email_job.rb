class FeedbackEmailJob < NotifyJob
  class SendingDisabledError < RuntimeError; end

  rescue_from SendingDisabledError do
    reschedule_job
  end

  before_perform if: :feedback_sending_disabled? do
    raise SendingDisabledError, "Feedback sending is currently disabled"
  end

  def perform(feedback)
    client.send_email(
      email_address: Site.feedback_address,
      template_id: "68009505-3bc4-49b6-b1b5-c3f36967f9b4",
      reference: feedback.to_gid_param,
      personalisation: {
        comment: feedback.comment,
        link_or_title: feedback.petition_link_or_title,
        email: feedback.email,
        user_agent: feedback.user_agent
      }
    )
  end

  private

  def feedback_sending_disabled?
    Site.disable_feedback_sending?
  end
end
