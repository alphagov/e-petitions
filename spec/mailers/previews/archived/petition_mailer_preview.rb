# Preview all emails at http://localhost:3000/rails/mailers/archived/petition_mailer

module Archived
  class PetitionMailerPreview < ActionMailer::Preview
    def email_signer
      email = Archived::Petition::Email.last
      petition = email.petition
      signature = petition.signatures.validated.last

      Archived::PetitionMailer.email_signer(petition, signature, email)
    end

    def email_creator
      email = Archived::Petition::Email.last
      petition = email.petition
      signature = petition.creator

      Archived::PetitionMailer.email_creator(petition, signature, email)
    end

    def mailshot_for_signer
      mailshot = Archived::Petition::Mailshot.last
      petition = mailshot.petition
      signature = petition.signatures.validated.last

      Archived::PetitionMailer.mailshot_for_signer(petition, signature, mailshot)
    end

    def mailshot_for_creator
      mailshot = Archived::Petition::Mailshot.last
      petition = mailshot.petition
      signature = petition.creator

      Archived::PetitionMailer.mailshot_for_creator(petition, signature, mailshot)
    end

    def notify_signer_of_threshold_response
      petition = Archived::Petition.with_response.last
      signature = petition.signatures.validated.last

      Archived::PetitionMailer.notify_signer_of_threshold_response(petition, signature)
    end

    def notify_creator_of_threshold_response
      petition = Archived::Petition.with_response.last
      signature = petition.creator

      Archived::PetitionMailer.notify_creator_of_threshold_response(petition, signature)
    end

    def notify_signer_of_debate_scheduled
      petition = Archived::Petition.debated.last
      signature = petition.signatures.validated.last

      Archived::PetitionMailer.notify_signer_of_debate_scheduled(petition, signature)
    end

    def notify_creator_of_debate_scheduled
      petition = Archived::Petition.debated.last
      signature = petition.creator

      Archived::PetitionMailer.notify_creator_of_debate_scheduled(petition, signature)
    end

    def notify_signer_of_positive_debate_outcome
      petition = Archived::Petition.debated.last
      signature = petition.signatures.validated.last

      Archived::PetitionMailer.notify_signer_of_debate_outcome(petition, signature)
    end

    def notify_creator_of_positive_debate_outcome
      petition = Archived::Petition.debated.last
      signature = petition.creator

      Archived::PetitionMailer.notify_creator_of_debate_outcome(petition, signature)
    end

    def notify_signer_of_negative_debate_outcome
      petition = Archived::Petition.not_debated.last
      signature = petition.signatures.validated.last

      Archived::PetitionMailer.notify_signer_of_debate_outcome(petition, signature)
    end

    def notify_creator_of_negative_debate_outcome
      petition = Archived::Petition.not_debated.last
      signature = petition.creator

      Archived::PetitionMailer.notify_creator_of_debate_outcome(petition, signature)
    end
  end
end
