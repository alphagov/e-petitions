class EnqueuePetitionStatisticsUpdatesJob < ApplicationJob
  queue_as :low_priority

  delegate :disable_daily_update_statistics_job?, to: :Site

  def perform(timestamp)
    return if disable_daily_update_statistics_job?

    Petition.signed_since(timestamp.in_time_zone).find_each do |petition|
      UpdatePetitionStatisticsJob.perform_later(petition)
    end
  end
end
