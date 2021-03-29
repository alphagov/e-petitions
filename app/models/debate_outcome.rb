class DebateOutcome < ActiveRecord::Base
  include Translatable

  translate :overview, :transcript_url, :video_url, :debate_pack_url

  belongs_to :petition, touch: true

  validates :petition, presence: true
  validates :debated_on, presence: true, if: :debated?

  with_options url: true, length: { maximum: 500 } do
    validates :transcript_url_en, :video_url_en, :debate_pack_url_en
    validates :transcript_url_cy, :video_url_cy, :debate_pack_url_cy
  end

  has_one_attached :image

  validates :image, image: {
    content_type: "image/jpeg",
    byte_size: 512.kilobytes,
    dimensions: {
      width: 648..1800, height: 365..1200,
      ratio: (1.5)..(1.8)
    }
  }

  after_create do
    Appsignal.increment_counter("petition.debated", 1)
    petition.touch(:debate_outcome_at) unless petition.debate_outcome_at?
  end

  after_save do
    petition.update_columns(debate_state: debate_state)
  end

  def date
    debated_on
  end

  private

  def debate_state
    debated? ? 'debated' : 'not_debated'
  end
end
