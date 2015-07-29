module EmailDelivery
  extend ActiveSupport::Concern

  #
  # Send a single email to a recipient informing them about a petition that they have signed
  # Implemented as a custom job rather than using action mailers #deliver_later so we can do
  # extra checking before sending the email
  #

  included do
    queue_as :default
  end

  def perform(signature:, timestamp_name:, petition:,
    requested_at_as_string:, mailer: PetitionMailer.name, logger: nil)

    @mailer = mailer.constantize
    @signature = signature
    @petition = petition
    @requested_at = requested_at_as_string.in_time_zone
    @timestamp_name = timestamp_name
    @logger = logger

    if can_send_email?
      send_email
      record_email_sent
    end
  end

  private

  attr_reader :mailer, :signature, :timestamp_name, :petition, :requested_at

  def can_send_email?
    petition_has_not_been_updated? && email_not_previously_sent?
  end

  def send_email
    create_email.deliver_now

    rescue Errno::ECONNREFUSED, Errno::ETIMEDOUT, Net::SMTPError, Timeout::Error => e
      # log that the send failed
      logger.info("#{e.class.name} while sending email for #{self.class.name} to: #{signature.email} for #{signature.petition.action}")

      #
      # TODO: check the error and if it is a n AWS SES rate error:
      # 454 Throttling failure: Maximum sending rate exceeded
      # 454 Throttling failure: Daily message quota exceeded
      #
      # Then reschedule the send for a day later rather than keep failing
      #

      # reraise to rerun the job later via the job retry mechanism
      raise e
  end

  def create_email
    raise NotImplementedError.new "Including classes must implement #create_email method"
  end

  def record_email_sent
    signature.set_email_sent_at_for timestamp_name, to: petition_timestamp
  end

  def petition_timestamp
    petition.get_email_requested_at_for(timestamp_name)
  end

  # We do not want to send the email if the petition has been updated
  # As email sending is enqueued straight after a petition has been updated
  def petition_has_not_been_updated?
    (petition_timestamp - requested_at).abs < 1
  end

  #
  # Have we already sent an email for this petition version?
  # If we have then the timestamp for the signature will match the timestamp for the petition
  #
  def email_not_previously_sent?
    # check that the signature is still in the list of signatures
    petition.signatures_to_email_for(timestamp_name).where(id: signature.id).exists?
  end
end
