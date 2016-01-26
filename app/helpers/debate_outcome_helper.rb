module DebateOutcomeHelper
  def debate_outcome_image(debate_outcome)
    sources = ['1x', '2x'].map { |size| "#{debate_outcome.commons_image.url(size)} #{size}" }
    image_tag(debate_outcome.commons_image.url('2x'), 'aria-hidden': '', srcset: sources.join(', '))
  end
end
