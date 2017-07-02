class DebatedPetitionsJob < ApplicationJob
  queue_as :high_priority

  def perform(date)
    Petition.mark_petitions_as_debated!(date.to_date)
    Archived::Petition.mark_petitions_as_debated!(date.to_date)
  end
end
