module HomeHelper
  class PetitionCountsDecorator
    delegate :each, to: :counts

    def empty?
      counts.all? { |_, count| count.zero? }
    end

    def [](state)
      counts.fetch(state, 0)
    end

    private

    def counts
      @counts ||= generate_counts
    end

    def generate_counts
      scope, counts = Petition.visible, {}
      counts[:with_response] = scope.with_response.count
      counts[:with_debate_outcome] = scope.with_debate_outcome.count
      counts
    end
  end

  def actioned_petition_counts(&block)
    counts = petition_count_decorator
    yield counts unless counts.empty?
  end

  def explanation_petition_counts(&block)
    yield petition_count_decorator
  end

  def petition_count_decorator
    @_petition_count_decorator ||= PetitionCountsDecorator.new
  end
  private :petition_count_decorator

  def petition_count(key, count)
    t(:"#{key}.html", scope: :"petitions.counts", count: count, formatted_count: number_with_delimiter(count))
  end

  def trending_petitions
    petitions = Petition.trending.to_a
    yield petitions unless petitions.empty?
  end
end
