class UpdatePetitionStatisticsJob < ApplicationJob
  queue_as :low_priority

  def perform(petition)
    petition.statistics.refresh!
  end
end
