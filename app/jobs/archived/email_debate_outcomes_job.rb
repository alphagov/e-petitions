module Archived
  class EmailDebateOutcomesJob < ApplicationJob
    include EmailAllPetitionSignatories

    self.email_delivery_job_class = Archived::DeliverDebateOutcomeEmailJob
    self.timestamp_name = 'debate_outcome'
  end
end
