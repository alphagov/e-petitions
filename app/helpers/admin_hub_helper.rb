module AdminHubHelper
  class ActionCountsDecorator
    delegate :each, :empty?, to: :counts

    private

    def counts
      @counts ||= generate_counts
    end

    def generate_counts
      counts = []
      counts << [:in_moderation, Petition.in_moderation.count]
      counts << [:awaiting_response, Petition.visible.awaiting_response.count]
      counts << [:in_debate_queue, Petition.in_debate_queue.count]
      counts << [:all, Petition.all.count]
    end
  end

  def action_counts(&block)
    counts = ActionCountsDecorator.new
    yield counts
  end

  def action_count(key, count)
    t(:"#{key}.html", scope: :"petitions.action_counts", formatted_count: number_with_delimiter(count))
  end
end
