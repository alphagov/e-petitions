class EmailDebateOutcomesJob < ActiveJob::Base
  include EmailAllPetitionSignatories

  queue_as :email_debate_outcomes

  self.email_delivery_job_class = DeliverDebateOutcomeEmailJob
  self.timestamp_name = 'debate_outcome'
end
