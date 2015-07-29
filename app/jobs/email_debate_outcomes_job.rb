class EmailDebateOutcomesJob < EmailPetitionSignatoriesJob
  def email_delivery_job_class
    EmailDeliveryJobs::DebateOutcome
  end

  def timestamp_name
    'debate_outcome'
  end
end
