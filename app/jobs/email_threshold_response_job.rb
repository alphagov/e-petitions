class PleaseRetryEmailJob < StandardError
end

class EmailThresholdResponseJob < ActiveJob::Base
  queue_as :default

  def setup_job(petition, email_requested_at, mailer, threshold_logger)
    @petition = petition
    @email_requested_at = email_requested_at.in_time_zone
    @mailer = mailer.constantize
    @logger = threshold_logger || construct_threshold_logger
  end

  def perform(petition, email_requested_at, mailer, threshold_logger = nil)
    setup_job(petition, email_requested_at, mailer, threshold_logger)
    return unless newest_threshold_email_request?

    @logger.info("Starting job for petition '#{petition.title}' with email requested at : #{petition.email_requested_at}")
    email_signees
    @logger.info("Finished job for petition '#{@petition.title}'")

    assert_all_signees_notified
  end

  private

  # admins can modify threshold response message multiple times
  # each of those modifications enqueues a new job to send out emails
  # we want to execute only the latest job enqueued
  def newest_threshold_email_request?
    @petition.email_requested_at.to_i == @email_requested_at.to_i
  end

  def email_signees
    @petition.need_emailing.find_each do |signature|
      begin
        @mailer.notify_signer_of_threshold_response(@petition, signature).deliver_now
        signature.update_attribute(:last_emailed_at, @petition.email_requested_at)
      rescue Errno::ECONNREFUSED, Errno::ETIMEDOUT, Net::SMTPError => e
        # try this one again later
        @logger.info("#{e.class.name} while sending to: #{signature.email}")
      end
    end
  end

  def assert_all_signees_notified
    return if @petition.need_emailing.count == 0

    @logger.info("Raising error to force a retry of email send of '#{@petition.title}'")
    raise PleaseRetryEmailJob
  end

  def construct_threshold_logger
    logfilename = "threshold_response_for_petition_id_#{@petition_id}.log"
    AuditLogger.new(Rails.root.join('log', logfilename), 'Email threshold response error')
  end
end
