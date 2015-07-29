class EmailThresholdResponseJob < ActiveJob::Base
  include EmailAllPetitionSignatories

  def email_delivery_job_class
    DeliverThresholdResponseEmailJob
  end

  def timestamp_name
    'government_response'
  end
end
