class EmailThresholdResponseJob < EmailPetitionSignatories::Job
  def self.run_later_tonight(petition, requested_at = Time.current)
    petition.set_email_requested_at_for('government_response', to: requested_at)
    super(petition, petition.get_email_requested_at_for('government_response'))
  end

  def perform(petition, requested_at_string, mailer = PetitionMailer.name, logger = nil)
    @mailer = mailer.constantize
    worker(petition, requested_at_string, logger).do_work!
  end

  def timestamp_name
    'government_response'
  end

  def create_email(petition, signature)
    @mailer.notify_signer_of_threshold_response(petition, signature)
  end
end
