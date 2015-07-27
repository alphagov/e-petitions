module EmailDeliveryJobs
  class Base < ActiveJob::Base

    #
    # Send a single email to a recipient informing them about a petition that they have signed
    # Implemented as a custom job rather than using action mailers #deliver_later so we can do
    # extra checking before sending the email
    #

    queue_as :default

    def perform(signature:, timestamp_name:, petition:,
      requested_at_as_string:, mailer: PetitionMailer.name, logger: nil)

      @mailer = mailer.constantize
      @signature = signature
      @petition = petition
      @requested_at = requested_at_as_string.in_time_zone
      @timestamp_name = timestamp_name
      @logger = logger

      if petition_has_not_been_updated?
        send_email
        record_email_sent
      end
    end

    private

    attr_reader :mailer, :signature, :timestamp_name, :petition, :requested_at

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
      raise NotImplementedError.new "Extending classes must implement create_email"
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
      petition_timestamp.to_i == requested_at.to_i
    end
  end
end
