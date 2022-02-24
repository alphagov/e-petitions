class PrivacyNotification < ActiveRecord::Base
  PETITION_LIMIT = 5
  PETITION_SCOPE = lambda {
    not_anonymized.moderated.distinct.by_most_recent.limit(PETITION_LIMIT)
  }

  has_one :signature, foreign_key: :uuid
  has_many :signatures, -> { validated }, foreign_key: :uuid
  has_many :petitions, PETITION_SCOPE, through: :signatures

  delegate :name, :email, to: :signature

  def remaining_petition_count
    [petitions.limit(nil).count - PETITION_LIMIT, 0].max
  end
end
