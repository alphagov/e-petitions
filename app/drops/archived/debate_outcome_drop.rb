module Archived
  class DebateOutcomeDrop < ApplicationDrop
    def initialize(outcome)
      @outcome = outcome
    end

    def overview
      @outcome.overview.presence
    end

    def video_url
      @outcome.video_url.presence
    end

    def transcript_url
      @outcome.transcript_url.presence
    end

    def debate_pack_url
      @outcome.debate_pack_url.presence
    end

    def public_engagement_url
      @outcome.public_engagement_url.presence
    end

    def debate_summary_url
      @outcome.debate_summary_url.presence
    end
  end
end
