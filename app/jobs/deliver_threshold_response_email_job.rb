class DeliverThresholdResponseEmailJob < ActiveJob::Base
  include EmailDelivery

  queue_as :deliver_threshold_response_email

  def create_email
    mailer.notify_signer_of_threshold_response signature.petition, signature
  end
end
