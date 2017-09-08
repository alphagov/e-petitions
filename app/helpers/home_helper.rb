module HomeHelper
  class ActionedPetitionsDecorator
    FACETS = [
      :awaiting_response,
      :with_response,
      :awaiting_debate,
      :with_debated_outcome,
      :not_debated
    ]

    delegate :each, to: :actioned

    def empty?
      actioned.all? { |_, actioned| actioned[:count].zero? }
    end

    def [](state)
      actioned.fetch(state, 0)
    end

    def with_result
      {:with_response => actioned[:with_response], :with_debated_outcome => actioned[:with_debated_outcome]}
    end

    private

    def actioned
      @actioned ||= generate_actioned
    end

    def generate_actioned(limit = 3)
      scope, facets = Petition.visible, Petition.facet_definitions

      FACETS.each_with_object({}) do |action, actioned|
        facet = scope.instance_exec(&facets[action])
        actioned[action] = { count: facet.count, list: facet.limit(limit) }
      end
    end
  end

  def any_actioned_petitions?
    !actioned_petitions_decorator.empty?
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

  def no_petitions_yet?
    return @_no_petitions_yet if defined?(@_no_petitions_yet)
    @_no_petitions_yet = Petition.visible.empty?
  end

  def petition_count(key, count)
    t(:"#{key}.html", scope: :"petitions.counts", count: count, formatted_count: number_with_delimiter(count))
  end

  def trending_petitions
    petitions = Petition.trending.to_a
    yield petitions unless petitions.empty?
  end
end
