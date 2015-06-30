class EmailPetitionSignatories
  class PleaseRetry < StandardError; end

  class Job < ActiveJob::Base
    queue_as :default

    def self.run_later_tonight(petition, requested_at, *extra_args)
      set(wait_until: later_tonight).
        perform_later(petition, requested_at.getutc.iso8601, *extra_args)
    end

    def self.later_tonight
      1.day.from_now.at_midnight + rand(240).minutes + rand(60).seconds
    end
    private_class_method :later_tonight

    def worker(petition, requested_at_string, logger)
      Worker.new(self, petition, requested_at_string, logger)
    end
  end

  class Worker
    def initialize(job, petition, requested_at_string, logger = nil)
      @job = job
      @petition = petition
      @requested_at = requested_at_string.in_time_zone
      @logger = logger || construct_logger
    end

    def do_work!
      return unless newest_request?

      logger.info("Starting job for petition '#{petition.action}' with email requested at: #{petition_timestamp}")
      email_signees
      logger.info("Finished job for petition '#{petition.action}'")

      assert_all_signees_notified
    end

    private

    attr_reader :job, :petition, :requested_at, :logger

    delegate :timestamp_name, :create_email, to: :job

    def petition_timestamp
      petition.get_email_requested_at_for(timestamp_name)
    end

    def signatures_to_email
      petition.signatures_to_email_for(timestamp_name)
    end

    def send_email_to(signature)
      create_email(petition, signature).deliver_later
      signature.set_email_sent_at_for(timestamp_name, to: petition_timestamp)
    end

    # admins can ask to send the email multiple times and each time they
    # ask we enqueues a new job to send out emails with a new timestamp
    # we want to execute only the latest job enqueued
    def newest_request?
      # NOTE: to_i comparison is used to cater for precision differences
      # between DB timestamp (petition_timestamp precise to fractional
      # seconds) and job timestamp (requested_at - only seconds precise)
      petition_timestamp.to_i == requested_at.to_i
    end

    def email_signees
      signatures_to_email.find_each do |signature|
        begin
          send_email_to(signature)
        rescue Errno::ECONNREFUSED, Errno::ETIMEDOUT, Net::SMTPError => e
          # try this one again later
          logger.info("#{e.class.name} while sending email for #{job.class.name} to: #{signature.email}")
        end
      end
    end

    def assert_all_signees_notified
      return if signatures_to_email.count == 0

      logger.info("Raising error to force a retry of email send of '#{petition.action}'")
      raise PleaseRetry
    end

    def construct_logger
      logfilename = "#{job.class.name}_for_petition_id_#{petition.id}.log"
      AuditLogger.new(Rails.root.join('log', logfilename), "Email #{job.class.name} error")
    end
  end
end
