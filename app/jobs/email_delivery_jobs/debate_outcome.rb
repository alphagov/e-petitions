module EmailDeliveryJobs
  class DebateOutcome < Base

    def create_email
      mailer.notify_signer_of_debate_outcome signature.petition, signature
    end

  end
end
