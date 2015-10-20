class DeliverThresholdResponseEmailJob < ActiveJob::Base
  include EmailDelivery

  def create_email
    if signature.creator?
      mailer.notify_creator_of_threshold_response signature.petition, signature
    else
      mailer.notify_signer_of_threshold_response signature.petition, signature
    end
  end
end
