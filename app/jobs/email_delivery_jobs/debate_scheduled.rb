module EmailDeliveryJobs
  class DebateScheduled < Base

    def create_email
      mailer.notify_signer_of_debate_scheduled signature.petition, signature
    end

  end
end
