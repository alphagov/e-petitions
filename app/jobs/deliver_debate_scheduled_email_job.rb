class DeliverDebateScheduledEmailJob < ActiveJob::Base
  include EmailDelivery
  queue_as :deliver_debate_scheduled_email

  def create_email
    mailer.notify_signer_of_debate_scheduled signature.petition, signature
  end
end
