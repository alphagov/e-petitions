class EmailThresholdResponseJob < ActiveJob::Base
  include EmailAllPetitionSignatories

  self.email_delivery_job_class = DeliverThresholdResponseEmailJob
  self.timestamp_name = 'government_response'
end
