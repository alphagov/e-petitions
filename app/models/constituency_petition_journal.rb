class ConstituencyPetitionJournal < ActiveRecord::Base
  belongs_to :petition

  validates :petition, presence: true
  validates :constituency_id, presence: true, length: { maximum: 255 }
  validates :petition_id, uniqueness: { scope: [:constituency_id] }
  validates :signature_count, presence: true
end
