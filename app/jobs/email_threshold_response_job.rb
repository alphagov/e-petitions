class EmailThresholdResponseJob < ActiveJob::Base
  include EmailAllPetitionSignatories
  queue_as :email_threshold_response

  self.email_delivery_job_class = DeliverThresholdResponseEmailJob
  self.timestamp_name = 'government_response'
end
