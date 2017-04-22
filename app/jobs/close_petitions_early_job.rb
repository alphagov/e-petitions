class ClosePetitionsEarlyJob < ApplicationJob
  queue_as :high_priority

  class << self
    def schedule_for(time)
      set(wait_until: time).perform_later(time.iso8601)
    end
  end

  def perform(time)
    Petition.close_petitions_early!(time.in_time_zone)
  end
end
