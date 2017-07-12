module AdminHubHelper
  def petition_total_count
    Petition.all.count
  end

  def in_moderation_count
    Petition.in_moderation.count
  end

  def recently_in_moderation_count
    Petition.untagged.in_moderation.between_in_moderation_times(from: Site.moderation_near_overdue_in_days.ago, to: Time.current).count
  end

  def nearly_overdue_moderation_count
    Petition.untagged.in_moderation.between_in_moderation_times(from: Site.moderation_overdue_in_days.ago, to: Site.moderation_near_overdue_in_days.ago).count
  end

  def overdue_moderation_count
    Petition.untagged.in_moderation.overdue_in_moderation_time_limit.count
  end

  def tagged_count
    Petition.tagged.in_moderation.count
  end

  def summary_class_name_for_counts(nearly_overdue_count, overdue_count)
    if overdue_count > 0
      "queue-danger"
    elsif nearly_overdue_count > 0
      "queue-caution"
    else
      "queue-stable"
    end
  end

  class ActionCountsDecorator
    delegate :each, :empty?, to: :counts

    private

    def counts
      @counts ||= generate_counts
    end

    def generate_counts
      counts = []
      counts << [:awaiting_response, Petition.visible.awaiting_response.count]
      counts << [:in_debate_queue, Petition.in_debate_queue.count]
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
