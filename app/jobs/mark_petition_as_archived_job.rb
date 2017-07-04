class MarkPetitionAsArchivedJob < ApplicationJob
  queue_as :high_priority

  def perform(petition, archived_petition)
    if petition.signatures.count == archived_petition.signatures.count
      petition.update_column(:archived_at, Time.current)
    else
      self.class.set(wait: 5.minutes).perform_later(petition, archived_petition)
    end
  end
end
