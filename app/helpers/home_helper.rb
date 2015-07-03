module HomeHelper
  class ActionedPetitionsDecorator
    delegate :each, to: :actioned

    def empty?
      actioned.all? { |_, actioned| actioned[:count].zero? }
    end

    def [](state)
      actioned.fetch(state, 0)
    end

    private

    def actioned
      @actioned ||= generate_actioned
    end

    def generate_actioned
      scope, actioned = Petition.visible, {}
      with_response = scope.with_response.by_most_recent_response
      with_debate_outcome = scope.with_debate_outcome.by_most_recent_debate_outcome
      actioned[:with_response] = { count: with_response.count, list: with_response.limit(3) }
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
