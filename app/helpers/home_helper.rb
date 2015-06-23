module HomeHelper

  class PetitionCountsDecorator
    delegate :each, :empty?, to: :counts

    private

    def counts
      @counts ||= generate_counts
    end

    def generate_counts
      scope, counts = Petition.visible, []
      counts << [:with_response, scope.with_response.count]
      counts << [:with_debate_outcome, scope.with_debate_outcome.count]
      counts.all?{ |state, count| count.zero? } ? [] : counts
    end
  end

  def petition_counts(&block)
    counts = PetitionCountsDecorator.new
    yield counts unless counts.empty?
  end

  def petition_count(key, count)
    t(:"#{key}.html", scope: :"petitions.counts", count: count, formatted_count: number_with_delimiter(count))
  end

end
