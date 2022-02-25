class EmailPrivacyPolicyUpdatesJob < ApplicationJob
  queue_as :high_priority

  def perform(time:)
    Petition.where(created_at: time..).find_each do |petition|
      EmailPrivacyPolicyUpdateJob.perform_later(petition)
    end
  end
end
