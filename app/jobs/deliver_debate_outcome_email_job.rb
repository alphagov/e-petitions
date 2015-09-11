class DeliverDebateOutcomeEmailJob < ActiveJob::Base
  include EmailDelivery
  queue_as :deliver_debate_outcome_email

  def create_email
    mailer.notify_signer_of_debate_outcome signature.petition, signature
  end
end
