module Archived
  class EmailThresholdResponseJob < ApplicationJob
    include EmailAllPetitionSignatories

    self.email_delivery_job_class = Archived::DeliverThresholdResponseEmailJob
    self.timestamp_name = 'government_response'
  end
end
