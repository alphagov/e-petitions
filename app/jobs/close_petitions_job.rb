class ClosePetitionsJob < ApplicationJob
  queue_as :high_priority

  def perform(time)
    Petition.close_petitions!(time.in_time_zone)
  end
end
