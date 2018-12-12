class Petition < ActiveRecord::Base
  class Statistics < ActiveRecord::Base
    belongs_to :petition

    after_commit on: :create do
      UpdatePetitionStatisticsJob.perform_later(petition)
    end

    def refresh!(now = Time.current)
      update!(
        refreshed_at: now,
        duplicate_emails: refresh_duplicate_emails
      )
    end

    def refreshed?
      refreshed_at?
    end

    private

      def refresh_duplicate_emails
        petition.signatures.duplicate_emails
      end
  end
end
