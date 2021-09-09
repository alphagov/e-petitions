require 'net/smtp'

class EmailJob < ApplicationJob
  before_perform :set_appsignal_namespace

  class_attribute :mailer, :email

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

  queue_as :high_priority

  rescue_from *PERMANENT_FAILURES do |exception|
    log_exception(exception)
  end

  rescue_from *TEMPORARY_FAILURES do |exception|
    log_exception(exception)
    retry_job
  end

  def perform(*args)
    mailer.send(email, *args).deliver_now
  end

  private

  def log_exception(exception)
    logger.info(log_message(exception))
  end

  def log_message(exception)
    "#{exception.class.name} while sending email for #{self.class.name}"
  end

  def set_appsignal_namespace
    Appsignal.set_namespace("email")
  end
end
