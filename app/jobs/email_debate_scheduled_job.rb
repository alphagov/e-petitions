class EmailDebateScheduledJob < ActiveJob::Base
  include EmailAllPetitionSignatories

  queue_as :email_debate_scheduled

  self.email_delivery_job_class = DeliverDebateScheduledEmailJob
  self.timestamp_name = 'debate_scheduled'
end
