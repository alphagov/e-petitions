class EnqueuePetitionStatisticsUpdatesJob < ApplicationJob
  queue_as :low_priority

  def perform(timestamp)
    Petition.signed_since(timestamp.in_time_zone).find_each do |petition|
      UpdatePetitionStatisticsJob.perform_later(petition)
    end
  end
end
