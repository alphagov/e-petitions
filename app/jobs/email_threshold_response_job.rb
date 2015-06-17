class EmailThresholdResponseJob < ActiveJob::Base
  def self.run_later_tonight(petition)
    petition.set_email_requested_timestamp('email_requested_at', Time.current)
    EmailPetitionSignatories.run_later_tonight(self, petition, petition.get_email_requested_timestamp('email_requested_at'))
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
    'email_requested_at'
  end

  def create_email(petition, signature)
    @mailer.notify_signer_of_threshold_response(petition, signature)
  end
end
