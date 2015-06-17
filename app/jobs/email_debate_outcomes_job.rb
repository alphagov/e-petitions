class EmailDebateOutcomesJob < ActiveJob::Base
  def self.run_later_tonight(petition)
    petition.set_email_requested_at_for('debate_outcome', to: Time.current)
    EmailPetitionSignatories.run_later_tonight(self, petition, petition.get_email_requested_at_for('debate_outcome'))
  end

  queue_as :default

  def perform(petition, requested_at_string, mailer = PetitionMailer.name, threshold_logger = nil)
    @petition = petition
    @mailer = mailer.constantize
    worker(requested_at_string, threshold_logger).do_work!
  end

  def worker(requested_at_string, threshold_logger)
    EmailPetitionSignatories::Worker.new(self, @petition, requested_at_string, threshold_logger)
  end

  def timestamp_name
    'debate_outcome'
  end

  def create_email(petition, signature)
    @mailer.notify_signer_of_debate_outcome(petition, signature)
  end
end
