class EmailDebateScheduledJob < EmailPetitionSignatoriesJob
  def email_delivery_job_class
    EmailDeliveryJobs::DebateScheduled
  end

  def timestamp_name
    'debate_scheduled'
  end
end
