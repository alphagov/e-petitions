class EmailThresholdResponseJob < EmailPetitionSignatories::Job
  def self.run_later_tonight(petition)
    petition.set_email_requested_at_for('government_response', to: Time.current)
    super(petition, petition.get_email_requested_at_for('government_response'))
  end

  def perform(petition, requested_at_string, mailer = PetitionMailer.name, threshold_logger = nil)
    @mailer = mailer.constantize
    worker(petition, requested_at_string, threshold_logger).do_work!
  end

  def timestamp_name
    'government_response'
  end

  def create_email(petition, signature)
    @mailer.notify_signer_of_threshold_response(petition, signature)
  end
end
