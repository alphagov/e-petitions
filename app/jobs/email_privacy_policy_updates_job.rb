class EmailPrivacyPolicyUpdatesJob < ApplicationJob
  queue_as :high_priority

  def perform(time:)
    Petition.moderated.where(created_at: time..).find_each do |petition|
      EmailPrivacyPolicyUpdateJob.perform_later(petition: petition, time: time)
    end
  end
end
