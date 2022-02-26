class PrivacyNotification < ActiveRecord::Base
  PETITION_LIMIT = 5

  PETITION_SCOPE = lambda {
    moderated.distinct.by_most_recent
  }

  has_one :signature, foreign_key: :uuid
  has_many :signatures, -> { validated }, foreign_key: :uuid

  has_many :petitions, PETITION_SCOPE, through: :signatures do
    def sample
      applicable.limit(PETITION_LIMIT)
    end

    def remaining_count
      [applicable.count - PETITION_LIMIT, 0].max
    end

    private

    def applicable
      where(created_at: ignore_petitions_before..)
    end

    def ignore_petitions_before
      proxy_association.owner.ignore_petitions_before
    end
  end

  delegate :name, :email, to: :signature
end
