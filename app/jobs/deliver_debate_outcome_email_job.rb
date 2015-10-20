class DeliverDebateOutcomeEmailJob < ActiveJob::Base
  include EmailDelivery

  def create_email
    if signature.creator?
      mailer.notify_creator_of_debate_outcome signature.petition, signature
    else
      mailer.notify_signer_of_debate_outcome signature.petition, signature
    end
  end
end
