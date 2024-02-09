class EmailConstituencyJob < ApplicationJob
  include EmailAllPetitionSignatories

  self.email_delivery_job_class = DeliverPetitionMailshotJob
  self.timestamp_name = 'petition_mailshot'

  attr_reader :mailshot

  # It's likely that the email got deleted so we just log the error and move on
  rescue_from ActiveJob::DeserializationError do |exception|
    log_exception(exception)
  end

  def perform(args)
    @mailshot = args[:mailshot]
    super
  end

  private

  def mailer_arguments(signature)
    super.merge(mailshot: mailshot)
  end

  def log_exception(exception)
    logger.info(log_message(exception))
  end

  def log_message(exception)
    "#{exception.class.name} while running #{self.class.name}"
  end
end
