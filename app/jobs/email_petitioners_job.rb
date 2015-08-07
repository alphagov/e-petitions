class EmailPetitionersJob < ActiveJob::Base
  include EmailAllPetitionSignatories

  self.email_delivery_job_class = DeliverPetitionEmailJob
  self.timestamp_name = 'petition_email'

  attr_reader :email

  def perform(**args)
    @email = args[:email]
    super
  end

  private

  def mailer_arguments(signature)
    super.merge(email: email)
  end
end
