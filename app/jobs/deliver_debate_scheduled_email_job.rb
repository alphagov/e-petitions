class DeliverDebateScheduledEmailJob < ActiveJob::Base
  include EmailDelivery

  def create_email
    mailer.notify_signer_of_debate_scheduled signature.petition, signature
  end

end
