class ReferOrRejectPetitionsJob < ApplicationJob
  queue_as :high_priority

  def perform(time)
    Petition.refer_or_reject_petitions!(time.in_time_zone)
  end
end
