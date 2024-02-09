module EmailAllPetitionSignatories
  # Concern to add shared functionality to ActiveJob classes
  # that are responsible for enqueuing send email jobs

  extend ActiveSupport::Concern

  included do
    before_perform :set_appsignal_namespace

    class_attribute :email_delivery_job_class
    class_attribute :timestamp_name

    attr_reader :petition, :requested_at, :scope

    queue_as :high_priority

    with_options(skip_after_callbacks_if_terminated: true) do
      define_callbacks :enqueue_send_email_jobs
    end
  end

  module ClassMethods
    def run_later_tonight(**args)
      petition, @requested_at = args[:petition], args[:requested_at]

      petition.set_email_requested_at_for(timestamp_name, to: requested_at)
      set(wait_until: later_tonight).perform_later(**args.merge(requested_at: requested_at_iso8601))
    end

    def before_enqueue_send_email_jobs(*filters, &blk)
      set_callback(:enqueue_send_email_jobs, :before, *filters, &blk)
    end

    def after_enqueue_send_email_jobs(*filters, &blk)
      set_callback(:enqueue_send_email_jobs, :after, *filters, &blk)
    end

    private

    def requested_at
      @requested_at ||= Time.current
    end

    def requested_at_iso8601
      requested_at.getutc.iso8601(6)
    end

    def later_tonight
      midnight + random_interval
    end

    def midnight
      requested_at.end_of_day
    end

    def random_interval
      rand(240).minutes + rand(60).seconds
    end
  end

  def perform(args)
    @petition = args[:petition]
    @requested_at = args[:requested_at]
    @scope = args[:scope]

    # If the petition has been updated since the job
    # was queued then don't send the emails.
    unless petition_has_been_updated?
      enqueue_send_email_jobs
    end
  end

  private

  # Batches the signataries to send emails to in groups of 1000
  # and enqueues a job to do the actual sending
  def enqueue_send_email_jobs
    Appsignal.without_instrumentation do
      run_callbacks :enqueue_send_email_jobs do
        signatures_to_email.find_each do |signature|
          email_delivery_job_class.perform_later(**mailer_arguments(signature))
        end
      end
    end
  end

  def mailer_arguments(signature)
    {
      signature:      signature,
      timestamp_name: timestamp_name,
      petition:       petition,
      requested_at:   requested_at
    }
  end

  # admins can ask to send the email multiple times and each time they
  # ask we enqueues a new job to send out emails with a new timestamp
  # we want to execute only the latest job enqueued
  def petition_has_been_updated?
    (petition_timestamp - requested_at.in_time_zone).abs > 1
  end

  def petition_timestamp
    petition.get_email_requested_at_for(timestamp_name)
  end

  def signatures_to_email
    petition.signatures_to_email_for(timestamp_name, scope)
  end

  def set_appsignal_namespace
    Appsignal.set_namespace("email")
  end
end
