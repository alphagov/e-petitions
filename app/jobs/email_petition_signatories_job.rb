class EmailPetitionSignatoriesJob < ActiveJob::Base
  queue_as :default

  def self.run_later_tonight(petition, requested_at, *extra_args)
    set(wait_until: later_tonight).
      perform_later(petition, requested_at.getutc.iso8601, *extra_args)
  end

  def self.later_tonight
    1.day.from_now.at_midnight + rand(240).minutes + rand(60).seconds
  end
  private_class_method :later_tonight


  def perform(petition, requested_at_string)
    @petition = petition
    @requested_at = requested_at_string.in_time_zone
    do_work!
  end

  private

  attr_reader :petition, :requested_at

  def do_work!
    return if petition_has_been_updated?

    logger.info("Starting #{self.class.name} for petition '#{petition.action}' with email requested at: #{petition_timestamp}")
    enqueue_send_email_jobs
    logger.info("Finished #{self.class.name} for petition '#{petition.action}'")

    # TODO: removed check_all_assignees recieved email
    # as email is not sent from here.
    # Do we need to check that at all here?
  end

  #
  # Batches the signataries to send emails to in groups of 1000
  # and enqueues a job to do the actual sending
  #
  def enqueue_send_email_jobs
    signatures_to_email.find_each do |signature|
      email_delivery_job_class.perform_later(
        signature:                    signature,
        timestamp_name:               timestamp_name,
        petition:                     petition,
        requested_at_as_string:       requested_at.getutc.iso8601
      )
    end
  end

  # admins can ask to send the email multiple times and each time they
  # ask we enqueues a new job to send out emails with a new timestamp
  # we want to execute only the latest job enqueued
  def petition_has_been_updated?
    # NOTE: to_i comparison is used to cater for precision differences
    # between DB timestamp (petition_timestamp precise to fractional
    # seconds) and job timestamp (requested_at - only seconds precise)
    petition_timestamp.to_i != requested_at.to_i
  end

  def petition_timestamp
    petition.get_email_requested_at_for(timestamp_name)
  end

  def signatures_to_email
    petition.signatures_to_email_for(timestamp_name)
  end

  # The job class that handles the actual email sending for this job type
  def email_delivery_job_class
    raise NotImplementedError.new "Extending classes must implement email_delivery_job_class"
  end

  def timestamp_name
    raise NotImplementedError.new "Extending classes must implement timestamp_name"
  end
end


