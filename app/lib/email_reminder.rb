class EmailReminder
  # email out a list of all petitions that have reached the threshold or that have been marked for a response
  def self.threshold_email_reminder
    admin_users = AdminUser.by_role(AdminUser::MODERATOR_ROLE)
    if admin_users.any?
      petitions =  Petition.threshold.where(:notified_by_email => false).order(:signature_count)
      # only email if there are one or more petitions
      if petitions.any?
        logger.info('Sending threshold email')
        AdminMailer.threshold_email_reminder(admin_users, petitions).deliver_now

        # mark all petitions as having been notified by email
        petitions.each do |petition|
          petition.update_attribute(:notified_by_email, true)
        end
      end
    end
  rescue Exception => e
    logger.error("#{e.class.name} while processing threshold_email_reminders: #{e.message}", e)
  end

  def self.special_resend_of_signature_email_validation(date = '2011-08-14')
    scope = Signature.where(state: Signature::PENDING_STATE)
    scope = scope.where("created_at > ?", Date.new(2011, 8, 14))
    scope = scope.where("updated_at < ?", date.to_date)

    scope.find_each do |signature|
      begin
        PetitionMailer.special_resend_of_email_confirmation_for_signer(signature).deliver_now
      rescue Net::SMTPSyntaxError
        logger.warn("cannot send email to #{signature.email}")
        # ignore a syntax error
      end
      signature.update_attribute(:updated_at, Time.current)
      logger.info("Special resend sent to #{signature.email}")
    end
  end

  def self.logger
    unless @logger
      logfilename = "email_reminders.log"
      @logger = AuditLogger.new(Rails.root.join('log', logfilename), 'email reminders')
    end
    @logger
  end
end
