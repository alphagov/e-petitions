# Preview all emails at http://petitions.localhost:3000/rails/mailers/archived/petition_mailer

module Archived
  class PetitionMailerPreview < ApplicationMailerPreview
    def email_signer
      ::Archived::PetitionMailer.email_signer(petition, signature, email)
    end

    def email_creator
      ::Archived::PetitionMailer.email_creator(petition, creator, email)
    end

    def mailshot_for_signer
      ::Archived::PetitionMailer.mailshot_for_signer(petition, signature, mailshot)
    end

    def mailshot_for_creator
      ::Archived::PetitionMailer.mailshot_for_creator(petition, creator, mailshot)
    end

    def notify_signer_of_threshold_response
      ::Archived::PetitionMailer.notify_signer_of_threshold_response(petition, signature)
    end

    def notify_creator_of_threshold_response
      ::Archived::PetitionMailer.notify_creator_of_threshold_response(petition, creator)
    end

    def notify_signer_of_debate_scheduled
      ::Archived::PetitionMailer.notify_signer_of_debate_scheduled(petition, signature)
    end

    def notify_creator_of_debate_scheduled
      ::Archived::PetitionMailer.notify_creator_of_debate_scheduled(petition, creator)
    end

    def notify_signer_of_positive_debate_outcome
      ::Archived::PetitionMailer.notify_signer_of_positive_debate_outcome(petition, signature)
    end

    def notify_creator_of_positive_debate_outcome
      ::Archived::PetitionMailer.notify_creator_of_positive_debate_outcome(petition, creator)
    end

    def notify_signer_of_negative_debate_outcome
      ::Archived::PetitionMailer.notify_signer_of_negative_debate_outcome(not_debated_petition, not_debated_signature)
    end

    def notify_creator_of_negative_debate_outcome
      ::Archived::PetitionMailer.notify_creator_of_negative_debate_outcome(not_debated_petition, not_debated_creator)
    end

    private

    def petition
      mock(:archived_petition)
    end

    def creator
      petition.creator
    end

    def sponsor
      petition.sponsors.last
    end

    def signature
      petition.signatures.last
    end

    def email
      petition.emails.first
    end

    def mailshot
      petition.mailshots.first
    end

    def not_debated_petition
      mock(:not_debated_archived_petition)
    end

    def not_debated_creator
      not_debated_petition.creator
    end

    def not_debated_signature
      not_debated_petition.signatures.last
    end
  end
end
