# Preview all emails at http://localhost:3000/rails/mailers/archived/petition_mailer

module Archived
  class PetitionMailerPreview < ActionMailer::Preview
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
  end
end
