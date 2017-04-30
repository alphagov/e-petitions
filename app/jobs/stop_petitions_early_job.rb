class StopPetitionsEarlyJob < ApplicationJob
  queue_as :high_priority

  class << self
    def schedule_for(time)
      set(wait_until: time).perform_later(time.iso8601)
    end
  end

  def perform(time)
    time = time.in_time_zone
    cutoff_time = Parliament.notification_cutoff_at

    Petition.in_need_of_stopping.find_each do |petition|
      if petition.created_at >= cutoff_time
        case petition.state
        when Petition::VALIDATED_STATE
          NotifyCreatorOfValidatedPetitionBeingStoppedJob.perform_later(petition.creator_signature)
        when Petition::SPONSORED_STATE
          NotifyCreatorOfSponsoredPetitionBeingStoppedJob.perform_later(petition.creator_signature)
        end
      end

      petition.stop!(time)
    end
  end
end
