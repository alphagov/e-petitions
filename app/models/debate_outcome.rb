class DebateOutcome < ActiveRecord::Base
  VALID_OTHER_URLS = /\Ahttps?:\/\/(?:[a-z][\-\.a-z0-9]{0,63}\.parliament\.uk|www\.youtube\.com).*\z/
  VALID_VIDEO_URLS = /\Ahttps?:\/\/(?:(?:www\.)?parliamentlive\.tv|www\.youtube\.com).*\z/
  VALID_PUBLIC_ENGAGEMENT_URLS = /\Ahttps?:\/\/(?:committees\.parliament\.uk|ukparliament\.shorthandstories\.com).*\z/
  VALID_DEBATE_SUMMARY_URLS = /\Ahttps?:\/\/ukparliament\.shorthandstories\.com.*\z/

  belongs_to :petition, touch: true

  validates :petition, presence: true
  validates :debated_on, presence: true, if: :debated?

  with_options length: { maximum: 500 } do
    validates :transcript_url, :video_url, :debate_pack_url
    validates :public_engagement_url, :debate_summary_url
  end

  with_options allow_blank: true do
    with_options format: { with: VALID_OTHER_URLS } do
      validates :debate_pack_url, :transcript_url
    end

    with_options format: { with: VALID_VIDEO_URLS } do
      validates :video_url
    end

    with_options format: { with: VALID_PUBLIC_ENGAGEMENT_URLS } do
      validates :public_engagement_url
    end

    with_options format: { with: VALID_DEBATE_SUMMARY_URLS } do
      validates :debate_summary_url
    end
  end

  has_one_attached :image

  validates :image, image: {
    content_type: "image/jpeg",
    byte_size: 512.kilobytes,
    dimensions: {
      width: 630..1890, height: 355..1260,
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

  def to_liquid
    DebateOutcomeDrop.new(self)
  end

  private

  def debate_state
    debated? ? 'debated' : 'not_debated'
  end
end
