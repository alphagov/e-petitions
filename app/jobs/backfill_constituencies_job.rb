class BackfillConstituenciesJob < ApplicationJob
  queue_as :low_priority

  def perform(id: 0, since: nil)
    return if Site.disable_constituency_api?

    since = since.try(:in_time_zone)
    signatures = signatures_missing_constituency_id(id, since).to_a
    max_id = signatures.map(&:id).max

    signatures.each do |signature|
      next if signature.constituency_id?

      if constituency = signature.constituency
        signature.update_column(:constituency_id, constituency.external_id)
      end
    end

    if reschedule?(max_id, since)
      self.class.perform_later(id: max_id, since: since.try(:iso8601))
    end
  end

  private

  def signatures_missing_constituency_id(id, since)
    Signature.missing_constituency_id(since: since).batch(id)
  end

  def reschedule?(id, since)
    signatures_missing_constituency_id(id, since).exists?
  end
end
