class InvalidateSignaturesJob < ApplicationJob
  queue_as :high_priority

  rescue_from(ActiveJob::DeserializationError) do |exception|
    Appsignal.send_exception exception
  end

  def perform(invalidation)
    invalidation.invalidate!
  end
end
