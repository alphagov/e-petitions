class DissolutionNotification < ActiveRecord::Base
  has_one :signature, foreign_key: :uuid

  with_options class_name: "Signature", foreign_key: :uuid do
    has_many :creator_signatures, -> { validated.subscribed.creator.open_at_dissolution }
    has_many :signatures, -> { validated.subscribed.not_creator.open_at_dissolution }
  end

  with_options class_name: "Petition", source: :petition do
    has_many :created_petitions, -> { distinct.by_most_recent.limit(5) }, through: :creator_signatures
    has_many :petitions, -> { distinct.by_most_recent.limit(5) }, through: :signatures
  end

  delegate :name, :email, to: :signature

  class << self
    def reset!
      connection.truncate(table_name)
    end
  end

  def signer?
    petitions.any?
  end

  def remaining_petitions
    [petitions.limit(nil).count - 5, 0].max
  end

  def creator?
    created_petitions.any?
  end

  def remaining_created_petitions
    [created_petitions.limit(nil).count - 5, 0].max
  end
end
