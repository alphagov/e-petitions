class DebatedPetitionsJob < ActiveJob::Base
  def perform
    Petition.mark_petitions_as_debated!
  end
end
