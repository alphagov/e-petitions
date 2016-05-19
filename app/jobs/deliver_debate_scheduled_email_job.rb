class DeliverDebateScheduledEmailJob < ActiveJob::Base
  include EmailDelivery

  def create_email
    if signature.creator?
      mailer.notify_creator_of_debate_scheduled signature.petition, signature
    else
      mailer.notify_signer_of_debate_scheduled signature.petition, signature
    end
  end
end
