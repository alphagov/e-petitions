class ClosePetitionsJob < ActiveJob::Base
  queue_as :high_priority

  def perform
    Petition.close_petitions!
  end
end
