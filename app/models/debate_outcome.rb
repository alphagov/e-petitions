class DebateOutcome < ActiveRecord::Base
  belongs_to :petition, touch: true

  validates :petition, presence: true
  validates :debated_on, presence: true, if: :debated?
  validates :transcript_url, :video_url, length: { maximum: 500 }

  after_create do
    petition.touch(:debate_outcome_at)
  end

  after_save do
    petition.update_columns(debate_state: debate_state)
  end

  def date
    debated_on
  end

  private

  def debate_state
    debated? ? 'debated' : 'none'
  end
end
