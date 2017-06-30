module Archived
  class EmailDebateScheduledJob < ApplicationJob
    include EmailAllPetitionSignatories

    self.email_delivery_job_class = Archived::DeliverDebateScheduledEmailJob
    self.timestamp_name = 'debate_scheduled'
  end
end
