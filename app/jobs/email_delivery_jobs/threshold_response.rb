module EmailDeliveryJobs
  class ThresholdResponse < Base

    def create_email
      mailer.notify_signer_of_threshold_response signature.petition, signature
    end

  end
end
