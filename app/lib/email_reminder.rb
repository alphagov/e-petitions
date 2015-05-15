class EmailReminder

  # email out a list of all validated petitions for the department(s) that the admin user belongs to
  def self.admin_email_reminder
    admin_users = AdminUser.by_role(AdminUser::ADMIN_ROLE)
    admin_users.each do |user|
      petitions = Petition.for_state(Petition::VALIDATED_STATE).order('created_at desc')
      # only email if there are one or more petitions
      if petitions.any?

        # how many new petitions?
        # look back 3 days if today is Monday since emails only get sent on a week day
        since_when = Time.zone.now.strftime('%u') == '1' ? 3.days.ago : 1.day.ago
        new_petitions_count = Petition.for_state(Petition::VALIDATED_STATE).where('updated_at > ?', since_when).count

        logger.info(user.email)
        AdminMailer.admin_email_reminder(user, petitions, new_petitions_count).deliver_now
      end
    end
  rescue Exception => e
    logger.error("#{e.class.name} while processing admin_email_reminders: #{e.message}", e)
  end

  # email out a list of all petitions that have reached the threshold or that have been marked for a response
  def self.threshold_email_reminder
    admin_users = AdminUser.by_role(AdminUser::THRESHOLD_ROLE)
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
      signature.update_attribute(:updated_at, Time.zone.now)
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
