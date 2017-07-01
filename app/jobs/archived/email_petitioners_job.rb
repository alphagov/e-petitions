module Archived
  class EmailPetitionersJob < ApplicationJob
    include EmailAllPetitionSignatories

    self.email_delivery_job_class = Archived::DeliverPetitionEmailJob
    self.timestamp_name = 'petition_email'

    attr_reader :email

    # It's likely that the email got deleted so we just log the error and move on
    rescue_from ActiveJob::DeserializationError do |exception|
      log_exception(exception)
    end

    def perform(**args)
      @email = args[:email]
      super
    end

    private

    def mailer_arguments(signature)
      super.merge(email: email)
    end

    def log_exception(exception)
      logger.info(log_message(exception))
    end

    def log_message(exception)
      "#{exception.class.name} while running #{self.class.name}"
    end
  end
end
