class TrendingPetitionJournal < ActiveRecord::Base
  belongs_to :petition

  validates :petition, presence: true
  validates :date, presence: true
end
