module DebateOutcomeHelper
  DEBATE_OUTCOME_URLS = %i[video_url transcript_url debate_pack_url public_engagement_url debate_summary_url]

  OUTCOME_IMAGE_WIDTH = 1260.0
  OUTCOME_IMAGE_HEIGHT = 944.0
  OUTCOME_IMAGE_1X = [ OUTCOME_IMAGE_WIDTH / 2, OUTCOME_IMAGE_HEIGHT / 2 ]
  OUTCOME_IMAGE_2X = [ OUTCOME_IMAGE_WIDTH, OUTCOME_IMAGE_HEIGHT ]

  EMBEDDABLE_URL = /www\.youtube\.com\/(?:watch|live)/

  DebateOutcomeUrl = Struct.new(:title, :url)

  def debate_outcome_image(outcome, options = {})
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
    defaults = { srcset: sources.join(', '), alt: "Watch the petition '#{outcome.petition.action}' being debated" }

    image_tag(urls['2x'], defaults.merge(options))
  end

  def debate_outcome_links?(debate_outcome)
    DEBATE_OUTCOME_URLS.any? { |url| debate_outcome.public_send(:"#{url}?") }
  end

  def debate_outcome_links(debate_outcome)
    DEBATE_OUTCOME_URLS.map do |attribute|
      url = debate_outcome.public_send(:"#{attribute}")

      next unless url.present?
      next if url.match?(EMBEDDABLE_URL)

      title = I18n.t(attribute, scope: :"petitions.debate_outcomes.link_titles")

      DebateOutcomeUrl.new(title, url)
    end.compact
  end

  def debate_outcome_video(video_url)
    return unless video_url.present?
    return unless video_url.match?(EMBEDDABLE_URL)

    uri = URI.parse(video_url)
    params = Rack::Utils.parse_query(uri.query)

    if uri.path.starts_with?("/watch")
      uri.path = "/embed/#{params["v"]}"
    elsif uri.path.starts_with?("/live")
      uri.path = "/embed/#{uri.path.split('/').last}"
    end

    uri.query = { start: params["t"].to_i }.to_query

    tag.iframe(
      src: uri.to_s,
      frameborder: 0, allowfullscreen: true,
      referrerpolicy: "strict-origin-when-cross-origin",
      title: "YouTube video player"
    )
  end

  def video_service(url)
    uri = URI.parse(url)

    case uri.hostname
    when /youtube/
      "youtube.com"
    when /parliamentlive\.tv/
      "parliamentlive.tv"
    else
      uri.hostname
    end
  end
end
