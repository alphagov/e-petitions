require 'ostruct'

module DebateOutcomeHelper
  DEBATE_OUTCOME_URLS = %i[video_url transcript_url debate_pack_url public_engagement_url debate_summary_url]

  OUTCOME_IMAGE_WIDTH = 1260.0
  OUTCOME_IMAGE_HEIGHT = 944.0
  OUTCOME_IMAGE_1X = [ OUTCOME_IMAGE_WIDTH / 2, OUTCOME_IMAGE_HEIGHT / 2 ]
  OUTCOME_IMAGE_2X = [ OUTCOME_IMAGE_WIDTH, OUTCOME_IMAGE_HEIGHT ]

  def debate_outcome_image(outcome)
    if outcome.image.attached?
      urls = {
        '1x' => outcome_image_path(outcome.image.variant(resize_to_limit: OUTCOME_IMAGE_1X)),
        '2x' => outcome_image_path(outcome.image.variant(resize_to_limit: OUTCOME_IMAGE_2X))
      }
    else
      urls = {
        '1x' => image_path('graphics/graphic_house-of-commons.jpg'),
        '2x' => image_path('graphics/graphic_house-of-commons-2x.jpg')
      }
    end

    sources = urls.map { |size, url| "#{url} #{size}" }
    image_tag(urls['2x'], srcset: sources.join(', '), alt: "Watch the petition '#{outcome.petition.action}' being debated")
  end

  def debate_outcome_links?(debate_outcome)
    DEBATE_OUTCOME_URLS.any? { |url| debate_outcome.public_send(:"#{url}?") }
  end

  def debate_outcome_links(debate_outcome)
    DEBATE_OUTCOME_URLS.map do |url|
      if debate_outcome.public_send(:"#{url}?")
        OpenStruct.new(
          title: I18n.t(url, scope: :"petitions.debate_outcomes.link_titles"),
          url: debate_outcome.public_send(:"#{url}")
        )
      end
    end.compact
  end
end
