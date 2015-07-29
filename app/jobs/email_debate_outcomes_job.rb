class EmailDebateOutcomesJob < ActiveJob::Base
  include EmailAllPetitionSignatories

  def email_delivery_job_class
    DeliverDebateOutcomeEmailJob
  end

  def timestamp_name
    'debate_outcome'
  end
end
