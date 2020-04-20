module DebateOutcomeHelper
  Url = Struct.new(:name, :url) do
    def title
      I18n.t(name, scope: :"ui.debate_outcomes.link_titles")
    end

    def style
      name.to_s.dasherize
    end
  end

  def debate_outcome_image(outcome)
    sources = ['1x', '2x'].map { |size| "#{outcome.commons_image.url(size)} #{size}" }
    image_tag(outcome.commons_image.url('2x'), 'aria-hidden': '', srcset: sources.join(', '))
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
