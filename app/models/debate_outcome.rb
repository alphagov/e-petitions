class DebateOutcome < ActiveRecord::Base
  belongs_to :petition, touch: true

  validates :petition, presence: true
  validates :debated_on, presence: true, if: :debated?
  validates :transcript_url, :video_url, length: { maximum: 500 }

  after_create do
    petition.touch(:debate_outcome_at)
  end

  def date
    debated_on
  end
end
