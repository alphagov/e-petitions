class DebatedPetitionsJob < ActiveJob::Base
  queue_as :high_priority

  def perform
    Petition.mark_petitions_as_debated!
  end
end
