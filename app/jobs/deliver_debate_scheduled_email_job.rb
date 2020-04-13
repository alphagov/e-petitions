class DeliverDebateScheduledEmailJob < ApplicationJob
  include EmailDelivery

  def create_email(signature:, **args)
    if signature.creator?
      NotifyCreatorOfDebateScheduledEmailJob.new(signature)
    else
      NotifySignerOfDebateScheduledEmailJob.new(signature)
    end
  end
end
