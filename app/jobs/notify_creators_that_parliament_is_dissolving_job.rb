class NotifyCreatorsThatParliamentIsDissolvingJob < ApplicationJob
  queue_as :high_priority

  def perform
    petitions.find_each do |petition|
      NotifyCreatorThatParliamentIsDissolvingJob.perform_later(petition.creator)
    end
  end

  private

  def petitions
    Petition.open_at_dissolution
  end
end
