class AnonymiseSignaturesJob < ActiveJob::Base
  queue_as :high_priority

  def perform(time)
    Signature.anonymise!(time.in_time_zone)
  end
end
