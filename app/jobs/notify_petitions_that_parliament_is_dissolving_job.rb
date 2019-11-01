class NotifyPetitionsThatParliamentIsDissolvingJob < ApplicationJob
  queue_as :high_priority

  def perform
    DissolutionNotification.reset!

    petitions.find_each do |petition|
      NotifyPetitionThatParliamentIsDissolvingJob.perform_later(petition)
    end
  end

  private

  def petitions
    Petition.open_at_dissolution
  end
end
