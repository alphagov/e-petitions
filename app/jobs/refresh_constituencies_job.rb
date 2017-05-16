class RefreshConstituenciesJob < ApplicationJob
  queue_as :low_priority

  def perform
    Constituency.refresh!
  end
end
