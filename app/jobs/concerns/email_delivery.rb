require 'net/smtp'

module EmailDelivery
  # Send a single email to a recipient informing them about a petition that they have signed
  # Implemented as a custom job rather than using action mailers #deliver_later so we can do
  # extra checking before sending the email

  extend ActiveSupport::Concern

  PERMANENT_FAILURES = [
    Net::SMTPFatalError,
    Net::SMTPSyntaxError
  ]

  TEMPORARY_FAILURES = [
    Net::SMTPAuthenticationError,
    Net::OpenTimeout,
    Net::SMTPServerBusy,
    Errno::ECONNRESET,
    Errno::ECONNREFUSED,
    Errno::ETIMEDOUT,
    Timeout::Error,
    EOFError,
    SocketError
  ]

  included do
    before_perform :set_appsignal_namespace

    attr_reader :signature, :timestamp_name, :petition, :requested_at
    queue_as :low_priority

    rescue_from *PERMANENT_FAILURES do |exception|
      log_exception(exception)
    end

    rescue_from *TEMPORARY_FAILURES do |exception|
      log_exception(exception)
      retry_job
    end
  end

  def perform(args)
    @signature = args[:signature]
    @petition = args[:petition]
    @requested_at = args[:requested_at].in_time_zone
    @timestamp_name = args[:timestamp_name]

    if can_send_email?
      send_email
      record_email_sent
    end
  end

  private

  def log_exception(exception)
    logger.info(log_message(exception))
  end

  def log_message(exception)
    "#{exception.class.name} while sending email for #{self.class.name} to: #{signature.email} for #{petition.action}"
  end

  def can_send_email?
    petition_has_not_been_updated? && email_not_previously_sent?
  end

  def send_email
    create_email.deliver_now
  end

  def mailer
    case petition
    when Archived::Petition
      Archived::PetitionMailer
    when Petition
      PetitionMailer
    else
      raise ArgumentError, "Unknown petition type: #{petition.class}"
    end
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
    (petition_timestamp - requested_at.in_time_zone).abs < 1
  end

  # Have we already sent an email for this petition version?
  # If we have then the timestamp for the signature will match the timestamp for the petition
  def email_not_previously_sent?
    # check that the signature is still in the list of signatures
    petition.signatures_to_email_for(timestamp_name).where(id: signature.id).exists?
  end

  def set_appsignal_namespace
    Appsignal.set_namespace("email")
  end
end
