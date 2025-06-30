class ParliamentDrop < ApplicationDrop
  def initialize(parliament)
    @parliament = parliament
  end

  def threshold_for_response
    @parliament.formatted_threshold_for_response
  end

  def threshold_for_debate
    @parliament.formatted_threshold_for_debate
  end

  def dissolution_faq_url
    @parliament.dissolution_faq_url.presence
  end
end
