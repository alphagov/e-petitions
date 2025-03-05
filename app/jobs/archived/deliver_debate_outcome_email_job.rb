module Archived
  class DeliverDebateOutcomeEmailJob < ApplicationJob
    include EmailDelivery

    delegate :positive_debate_outcome?, to: :petition

    def create_email
      positive_debate_outcome? ? positive_outcome_email : negative_outcome_email
    end

    private

    def positive_outcome_email
      if signature.creator?
        mailer.notify_creator_of_positive_debate_outcome(petition, signature)
      else
        mailer.notify_signer_of_positive_debate_outcome(petition, signature)
      end
    end

    def negative_outcome_email
      if signature.creator?
        mailer.notify_creator_of_negative_debate_outcome(petition, signature)
      else
        mailer.notify_signer_of_negative_debate_outcome(petition, signature)
      end
    end
  end
end
