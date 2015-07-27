class EmailDebateOutcomesJob < EmailPetitionSignatoriesJob
  def self.run_later_tonight(petition)
    petition.set_email_requested_at_for('debate_outcome', to: Time.current)
    super(petition, petition.get_email_requested_at_for('debate_outcome'))
  end

  def email_delivery_job_class
    EmailDeliveryJobs::DebateOutcome
  end

  def timestamp_name
    'debate_outcome'
  end
end
