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
end
