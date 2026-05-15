module TimelineHelper
  PetitionEvent = Struct.new(:event, :timestamp, :context) do
    def path
      "petitions/events/#{event}"
    end
  end

  def petition_timeline(petition)
    return unless petition.published?

    events = []
    events << PetitionEvent.new(:petition_published, petition.published_at, nil)

    if petition.closed?
      events << PetitionEvent.new(:petition_closed, petition.closed_at, nil)
    end

    if petition.response_threshold_reached_at?
      events << PetitionEvent.new(:response_threshold_reached, petition.response_threshold_reached_at, nil)
    end

    if government_response = petition.government_response
      events << PetitionEvent.new(:government_responded, government_response.responded_on, government_response)
    end

    if petition.debate_threshold_reached_at?
      events << PetitionEvent.new(:debate_threshold_reached, petition.debate_threshold_reached_at, nil)
    end

    if petition.debate_scheduled_on?
      events << PetitionEvent.new(:debate_scheduled, petition.debate_scheduled_on, nil)
    end

    if debate_outcome = petition.debate_outcome
      if debate_outcome.debated?
        events << PetitionEvent.new(:parliament_debated, debate_outcome.debated_on, debate_outcome)
      else
        events << PetitionEvent.new(:parliament_did_not_debate, petition.debate_outcome_at, debate_outcome)
      end
    elsif petition.debated?
      events << PetitionEvent.new(:parliament_debated_pending_outcome, petition.scheduled_debate_date, petition)
    end

    petition.emails.each do |email|
      events << PetitionEvent.new(:related_activity, email.occurred_on, email)
    end

    events.sort_by!(&:timestamp)
    yield events
  end
end
