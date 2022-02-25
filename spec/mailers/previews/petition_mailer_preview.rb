# Preview all emails at http://localhost:3000/rails/mailers/petition_mailer
class PetitionMailerPreview < ActionMailer::Preview
  def email_confirmation_for_signer
    PetitionMailer.email_confirmation_for_signer(Signature.last)
  end

  def email_duplicate_signatures
    PetitionMailer.email_duplicate_signatures(Signature.last)
  end

  def gather_sponsors_for_petition
    PetitionMailer.gather_sponsors_for_petition(Petition.last)
  end

  def email_signer
    email = Petition::Email.last
    petition = email.petition
    signature = petition.signatures.validated.last

    PetitionMailer.email_signer(petition, signature, email)
  end

  def email_creator
    email = Petition::Email.last
    petition = email.petition
    signature = petition.creator

    PetitionMailer.email_creator(petition, signature, email)
  end

  def mailshot_for_signer
    mailshot = Petition::Mailshot.last
    petition = mailshot.petition
    signature = petition.signatures.validated.last

    PetitionMailer.mailshot_for_signer(petition, signature, mailshot)
  end

  def mailshot_for_creator
    mailshot = Petition::Mailshot.last
    petition = mailshot.petition
    signature = petition.creator

    PetitionMailer.mailshot_for_creator(petition, signature, mailshot)
  end

  def notify_creator_that_moderation_is_delayed
    petition = Petition.overdue_in_moderation.last
    signature = petition.creator
    subject = "Moderation of your petition has been delayed"
    body = "We are sorry, but moderation of your petition has been delayed due to an overwhelming number of requests."

    PetitionMailer.notify_creator_that_moderation_is_delayed(signature, subject, body)
  end

  def notify_signer_of_threshold_response
    petition = Petition.with_response.last
    signature = petition.signatures.validated.last

    PetitionMailer.notify_signer_of_threshold_response(petition, signature)
  end

  def notify_creator_of_threshold_response
    petition = Petition.with_response.last
    signature = petition.creator

    PetitionMailer.notify_creator_of_threshold_response(petition, signature)
  end

  def notify_creator_of_closing_date_change
    petition = Petition.open_at_dissolution.first
    signature = petition.creator

    PetitionMailer.notify_creator_of_closing_date_change(signature)
  end

  def notify_creator_of_sponsored_petition_being_stopped
    petition = Petition.where(state: "sponsored").last
    signature = petition.creator

    PetitionMailer.notify_creator_of_sponsored_petition_being_stopped(signature)
  end

  def notify_creator_of_validated_petition_being_stopped
    petition = Petition.where(state: "validated").last
    signature = petition.creator

    PetitionMailer.notify_creator_of_validated_petition_being_stopped(signature)
  end

  def debated_petition_signer_notification
    petition = Petition.debated.last
    signature = petition.signatures.validated.last

    PetitionMailer.notify_signer_of_debate_outcome(petition, signature)
  end

  def debated_petition_creator_notification
    petition = Petition.debated.last
    signature = petition.signatures.validated.last

    PetitionMailer.notify_creator_of_debate_outcome(petition, signature)
  end

  def not_debated_petition_signer_notification
    petition = Petition.not_debated.last
    signature = petition.signatures.validated.last

    PetitionMailer.notify_signer_of_debate_outcome(petition, signature)
  end

  def not_debated_petition_creator_notification
    petition = Petition.not_debated.last
    signature = petition.signatures.validated.last

    PetitionMailer.notify_creator_of_debate_outcome(petition, signature)
  end

  def privacy_policy_update_email
    privacy_notification = PrivacyNotification.last
    PetitionMailer.privacy_policy_update_email(privacy_notification)
  end
end
