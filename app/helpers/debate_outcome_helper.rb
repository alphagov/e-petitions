module DebateOutcomeHelper
  OUTCOME_IMAGE_WIDTH = 1296.0
  OUTCOME_IMAGE_HEIGHT = 972.0
  OUTCOME_IMAGE_1X = [ OUTCOME_IMAGE_WIDTH / 2, OUTCOME_IMAGE_HEIGHT / 2 ]
  OUTCOME_IMAGE_2X = [ OUTCOME_IMAGE_WIDTH, OUTCOME_IMAGE_HEIGHT ]

  Url = Struct.new(:name, :url) do
    def title
      I18n.t(name, scope: :"ui.debate_outcomes.link_titles")
    end

    def style
      name.to_s.dasherize
    end
  end

  def debate_outcome_image(outcome)
    if outcome.image.attached?
      urls = {
        '1x' => outcome_image_path(outcome.image.variant(resize_to_limit: OUTCOME_IMAGE_1X)),
        '2x' => outcome_image_path(outcome.image.variant(resize_to_limit: OUTCOME_IMAGE_2X))
      }
    else
      urls = {
        '1x' => image_path('frontend/senedd-chamber.jpg'),
        '2x' => image_path('frontend/senedd-chamber-2x.jpg')
      }
    end

    sources = urls.map { |size, url| "#{url} #{size}" }

    t(:"ui.debate_outcomes.image_tag_html", url: urls['2x'], srcset: sources.join(', '), action: outcome.petition.action)
  end

  def debate_outcome_links?(outcome)
    debate_outcome_links(outcome).any?
  end

  def debate_outcome_links(outcome)
    [].tap do |urls|
      if outcome.video_url?
        urls << Url.new(:video_url, outcome.video_url)
      end

      if outcome.transcript_url?
        urls << Url.new(:transcript_url, outcome.transcript_url)
      end

      if outcome.debate_pack_url?
        urls << Url.new(:debate_pack_url, outcome.debate_pack_url)
      end
    end
  end
end
