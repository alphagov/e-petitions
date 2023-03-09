class Petition < ActiveRecord::Base
  class Statistics < ActiveRecord::Base
    include ActiveSupport::NumberHelper

    belongs_to :petition

    after_commit on: :create do
      UpdatePetitionStatisticsJob.perform_later(petition)
    end

    def refresh!(now = Time.current)
      update!(
        refreshed_at: now,
        duplicate_emails: refresh_duplicate_emails,
        pending_rate: refresh_pending_rate,
        subscribers: refresh_subscribers
      )
    end

    def refreshed?
      refreshed_at?
    end

    def subscribers?
      if refreshed? && petition.published?
        super
      end
    end

    def subscribers
      if refreshed? && petition.published?
        super
      end
    end

    def subscriber_count
      if refreshed? && petition.published?
        number_to_delimited(subscribers)
      end
    end

    def subscription_rate
      if subscribers?
        number_to_percentage(Rational(subscribers, petition.signature_count) * 100, precision: 1)
      end
    end

    private

      def refresh_duplicate_emails
        petition.signatures.duplicate_emails
      end

      def refresh_pending_rate
        petition.signatures.pending_rate
      end

      def refresh_subscribers
        petition.signatures.subscribers
      end
  end
end
