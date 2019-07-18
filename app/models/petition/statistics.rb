class Petition < ActiveRecord::Base
  class Statistics < ActiveRecord::Base
    belongs_to :petition

    after_commit on: :create do
      UpdatePetitionStatisticsJob.perform_later(petition)
    end

    def refresh!(now = Time.current)
      update!(
        refreshed_at: now,
        duplicate_emails: refresh_duplicate_emails,
        pending_rate: refresh_pending_rate
      )
    end

    def refreshed?
      refreshed_at?
    end

    private

      def refresh_duplicate_emails
        petition.signatures.duplicate_emails
      end

      def refresh_pending_rate
        petition.signatures.pending_rate
      end
  end
end
