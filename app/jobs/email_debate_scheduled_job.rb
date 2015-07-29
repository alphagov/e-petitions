class EmailDebateScheduledJob < ActiveJob::Base
  include EmailAllPetitionSignatories

  def email_delivery_job_class
    DeliverDebateScheduledEmailJob
  end

  def timestamp_name
    'debate_scheduled'
  end
end
