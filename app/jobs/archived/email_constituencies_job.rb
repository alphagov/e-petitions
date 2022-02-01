module Archived
  class EmailConstituenciesJob < ApplicationJob
    queue_as :high_priority

    def perform(mailshot, constituency_ids, requested_at: nil)
      requested_at ||= Time.current

      constituency_ids.each do |constituency_id|
        Archived::EmailConstituencyJob.run_later_tonight(
          petition: mailshot.petition,
          mailshot: mailshot,
          scope: { constituency_id: constituency_id },
          requested_at: requested_at
        )
      end
    end
  end
end
