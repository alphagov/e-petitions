class NotifyCreatorThatModerationIsDelayedJob < EmailJob
  self.mailer = PetitionMailer
  self.email = :notify_creator_that_moderation_is_delayed

  queue_as :low_priority

  def perform(signature, subject, body)
    mailer.send(email, signature, subject, body).deliver_now
  end
end
