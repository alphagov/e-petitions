class PleaseRetryEmailJob < Exception
end

class EmailThresholdResponseJob < ActiveJob::Base
  queue_as :default

  def perform(petition, email_requested_at, mailer, threshold_logger = nil)
    email_requested_at = email_requested_at.in_time_zone if email_requested_at.is_a? String
    mailer = mailer.constantize if mailer.is_a? String
    @logger = threshold_logger
    threshold_logger(petition.id).info("Starting job for petition '#{petition.title}' with email requested at : #{petition.email_requested_at}")

    if petition.email_requested_at.to_i != email_requested_at.to_i
      return
    end

    i = 1
    petition.need_emailing.find_each do |signature|
      begin
        mailer.notify_signer_of_threshold_response(petition, signature).deliver_now
        threshold_logger(petition.id).info("Email #{i} to #{signature.email} sent")
        signature.update_attribute(:last_emailed_at, petition.email_requested_at)
      rescue Errno::ECONNREFUSED, Errno::ETIMEDOUT, Net::SMTPError => e
        # try this one again later
        threshold_logger(petition.id).info("#{e.class.name} while sending to: #{signature.email}")
      end
      i = i + 1
    end

    threshold_logger(petition.id).info("Finished job for petition '#{petition.title}'")
    if (petition.need_emailing.count > 0)
      threshold_logger(petition.id).info("Raising error to force a retry of email send of '#{petition.title}'")
      raise PleaseRetryEmailJob
    end

    rescue Exception => e
      # re-raise error so job is re-tried
      threshold_logger(petition.id).error("#{e.class.name} while processing EmailThresholdResponseJob (petition id #{petition.id}): #{e.message}", e.backtrace) unless e.is_a?(PleaseRetryEmailJob)
      raise e
  end

  private
  def threshold_logger(petition_id)
    unless @logger
      logfilename = "threshold_response_for_petition_id_#{petition_id}.log"
      @logger = AuditLogger.new(Rails.root.join('log', logfilename), 'Email threshold response error')
    end
    @logger
  end

  def failure
    threshold_logger(petition.id).error("EmailThresholdResponseJob has failed for petition '#{petition.title}'. Please see log file threshold_response_for_petition_id_#{petition.id}.log")
  end
end
