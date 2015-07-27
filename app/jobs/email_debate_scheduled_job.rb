class EmailDebateScheduledJob < EmailPetitionSignatoriesJob
  def self.run_later_tonight(petition)
    petition.set_email_requested_at_for('debate_scheduled', to: Time.current)
    super(petition, petition.get_email_requested_at_for('debate_scheduled'))
  end

  def email_delivery_job_class
    EmailDeliveryJobs::DebateScheduled
  end

  def timestamp_name
    'debate_scheduled'
  end
end
