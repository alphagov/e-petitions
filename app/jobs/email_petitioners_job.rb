class EmailPetitionersJob < ApplicationJob
  include EmailAllPetitionSignatories

  self.email_delivery_job_class = DeliverPetitionEmailJob
  self.timestamp_name = 'petition_email'

  # It's likely that the email got deleted so we just log the error and move on
  rescue_from ActiveJob::DeserializationError do |exception|
    log_exception(exception)
  end
end
