class EmailDebateScheduledJob < EmailPetitionSignatories::Job
  def self.run_later_tonight(petition)
    petition.set_email_requested_at_for('debate_scheduled', to: Time.current)
    super(petition, petition.get_email_requested_at_for('debate_scheduled'))
  end

  def perform(petition, requested_at_string, mailer = PetitionMailer.name, threshold_logger = nil)
    @mailer = mailer.constantize
    worker(petition, requested_at_string, threshold_logger).do_work!
  end

  def timestamp_name
    'debate_scheduled'
  end

  def create_email(petition, signature)
    @mailer.notify_signer_of_debate_scheduled(petition, signature)
  end
end
