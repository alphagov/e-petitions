module HomeHelper
  class ActionedPetitionsDecorator
    delegate :each, to: :actioned

    def empty?
      actioned.all? { |_, actioned| actioned[:count].zero? }
    end

    def [](state)
      actioned.fetch(state, 0)
    end

    def with_result
      {:with_response => actioned[:with_response], :with_debate_outcome => actioned[:with_debate_outcome]}
    end

    private

    def actioned
      @actioned ||= generate_actioned
    end

    def generate_actioned
      scope, actioned = Petition.visible, {}
      awaiting_response = scope.awaiting_response.by_waiting_for_response_longest
      with_response = scope.with_response.by_most_recent_response
      awaiting_debate_date = scope.awaiting_debate_date.by_waiting_for_debate_longest
      with_debate_outcome = scope.with_debate_outcome.by_most_recent_debate_outcome
      actioned[:awaiting_response] = { count: awaiting_response.count, list: awaiting_response.limit(3) }
      actioned[:with_response] = { count: with_response.count, list: with_response.limit(3) }
      actioned[:awaiting_debate_date] = { count: awaiting_debate_date.count, list: awaiting_debate_date.preload(:debate_outcome).limit(3) }
      actioned[:with_debate_outcome] = { count: with_debate_outcome.count, list: with_debate_outcome.preload(:debate_outcome).limit(3) }
      actioned
    end
  end

  def actioned_petitions(&block)
    actioned = actioned_petitions_decorator
    yield actioned unless actioned.empty?
  end

  def explanation_petitions(&block)
    yield actioned_petitions_decorator
  end

  def actioned_petitions_decorator
    @_actioned_petitions_decorator ||= ActionedPetitionsDecorator.new
  end
  private :actioned_petitions_decorator

  def petition_count(key, count)
    t(:"#{key}.html", scope: :"petitions.counts", count: count, formatted_count: number_with_delimiter(count))
  end

  def trending_petitions
    petitions = Petition.trending.to_a
    yield petitions unless petitions.empty?
  end
end
