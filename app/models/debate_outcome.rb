class DebateOutcome < ActiveRecord::Base
  belongs_to :petition, touch: true

  validates :petition, :debated_on, presence: true
  validates :petition_id, uniqueness: true
  validates :transcript_url, :video_url, length: { maximum: 500 }
end
