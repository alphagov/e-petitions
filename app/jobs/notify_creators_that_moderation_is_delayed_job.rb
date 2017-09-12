class NotifyCreatorsThatModerationIsDelayedJob < ApplicationJob
  queue_as :high_priority

  def perform(subject, body)
    petitions.find_each do |petition|
      NotifyCreatorThatModerationIsDelayedJob.perform_later(petition.creator, subject, body)
    end
  end

  private

  def petitions
    Petition.overdue_in_moderation
  end
end
