require 'net/smtp'

class EmailReminder
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
