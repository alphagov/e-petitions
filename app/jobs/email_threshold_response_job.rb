class PleaseRetryEmailJob < Exception
end

class EmailThresholdResponseJob < Struct.new(:petition_id, :email_requested_at, :petition_model, :mailer)
  def perform
    petition = petition_model.find(petition_id)
    logger(petition_id).info("Starting job for petition '#{petition.title}' with email requested at : #{petition.email_requested_at}")

    if petition.email_requested_at.to_i != email_requested_at.to_i
      return
    end

    i = 1
    petition.need_emailing.find_each do |signature|
      begin
        mailer.notify_signer_of_threshold_response(petition, signature).deliver
        logger(petition_id).info("Email #{i} to #{signature.email} sent")
        signature.update_attribute(:last_emailed_at, petition.email_requested_at)
      rescue Errno::ECONNREFUSED, Errno::ETIMEDOUT, Net::SMTPError => e
        # try this one again later
        logger(petition_id).info("#{e.class.name} while sending to: #{signature.email}")
      end
      i = i + 1
    end
      
    logger(petition_id).info("Finished job for petition '#{petition.title}'")
    if (petition.need_emailing.count > 0)
      logger(petition_id).info("Raising error to force a retry of email send of '#{petition.title}'")
      raise PleaseRetryEmailJob
    end
    
    rescue Exception => e
      # re-raise error so job is re-tried
      logger(petition_id).error("#{e.class.name} while processing EmailThresholdResponseJob (petition id #{petition_id}): #{e.message}", e.backtrace) unless e.is_a?(PleaseRetryEmailJob)
      raise e
  end
  
  def logger(petition_id)
    unless @logger
      logfilename = "threshold_response_for_petition_id_#{petition_id}.log"
      @logger = AuditLogger.new(Rails.root.join('log', logfilename), 'Email threshold response error')
    end
    @logger
  end
  
  def failure
    logger(petition_id).error("EmailThresholdResponseJob has failed for petition '#{petition.title}'. Please see log file threshold_response_for_petition_id_#{petition_id}.log")
  end
end
