class SignatureConfirmer
  def initialize(petition, email, mailer, valid_email_regex)
    @petition = petition
    @email = email
    @mailer = mailer
    @regex = valid_email_regex
  end


  def confirm!
    return unless @email.match(@regex)
    signatures = @petition.signatures.for_email(@email)
    case signatures.size
    when 0
      send_no_signature_for_petition_email
    when 1
      resend_confirmation_email_or_notify_already_confirmed(signatures)
    when 2
      email_multiple_signees(signatures)
    end
  end

  private

  def send_no_signature_for_petition_email
    @mailer.no_signature_for_petition(@petition, @email).deliver_now
  end

  def resend_confirmation_email_or_notify_already_confirmed(signatures)
    if signatures.first.pending?
      @mailer.email_confirmation_for_signer(signatures.first).deliver_now
    else
      @mailer.email_already_confirmed_for_signature(signatures.first).deliver_now
    end
  end

  def email_multiple_signees(signatures)
    if all_signatures_are_pending?(signatures)
      @mailer.two_pending_signatures(*signatures).deliver_now
    else
      pending_signature   = signatures.detect(&:pending?)
      validated_signature = signatures.detect(&:validated?)

      if pending_signature
        @mailer.one_pending_one_validated_signature(pending_signature, validated_signature).deliver_now
      else
        @mailer.double_signature_confirmation(signatures).deliver_now
      end
    end
  end

  def all_signatures_are_pending?(signatures)
    signatures.all?(&:pending?)
  end
end
