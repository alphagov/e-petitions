class EmailDebateScheduledJob < ActiveJob::Base
  include EmailAllPetitionSignatories

  self.email_delivery_job_class = DeliverDebateScheduledEmailJob
  self.timestamp_name = 'debate_scheduled'
end
