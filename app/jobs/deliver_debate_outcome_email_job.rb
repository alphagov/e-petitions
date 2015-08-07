class DeliverDebateOutcomeEmailJob < ActiveJob::Base
  include EmailDelivery

  def create_email
    mailer.notify_signer_of_debate_outcome signature.petition, signature
  end
end
