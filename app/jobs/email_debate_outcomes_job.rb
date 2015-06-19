class EmailDebateOutcomesJob < EmailPetitionSignatories::Job
  def self.run_later_tonight(petition)
    petition.set_email_requested_at_for('debate_outcome', to: Time.current)
    super(petition, petition.get_email_requested_at_for('debate_outcome'))
  end

  def perform(petition, requested_at_string, mailer = PetitionMailer.name, logger = nil)
    @mailer = mailer.constantize
    worker(petition, requested_at_string, logger).do_work!
  end

  def timestamp_name
    'debate_outcome'
  end

  def create_email(petition, signature)
    @mailer.notify_signer_of_debate_outcome(petition, signature)
  end
end
