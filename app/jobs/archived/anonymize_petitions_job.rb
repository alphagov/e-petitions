module Archived
  class AnonymizePetitionsJob < ApplicationJob
    queue_as :high_priority

    def perform(time)
      Archived::Petition.anonymize_petitions!(time.in_time_zone)
    end
  end
end
