require 'ostruct'

module DebateOutcomeHelper
  DEBATE_OUTCOME_URLS = %i[video_url transcript_url debate_pack_url]

  def debate_outcome_image(debate_outcome)
    sources = ['1x', '2x'].map { |size| "#{debate_outcome.commons_image.url(size)} #{size}" }
    image_tag(debate_outcome.commons_image.url('2x'), srcset: sources.join(', '), alt: "Watch the petition '#{debate_outcome.petition.action}' being debated", aria: { hidden: true })
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
