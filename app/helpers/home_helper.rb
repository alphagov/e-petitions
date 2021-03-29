module HomeHelper
  class ActionedPetitionsDecorator
    FACETS = [
      :referred,
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
      {:referred => actioned[:referred], :with_debated_outcome => actioned[:with_debated_outcome]}
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
    t(:"#{key}_html", scope: :"ui.counts", count: count, num: number_with_delimiter(count))
  end

  def trending_petitions(period: 24.hours, limit: 3)
    if Site.disable_trending_petitions?
      petitions = []
    else
      petitions = fetch_trending_petitions(trending_petitions_at, period, limit)
    end

    if block_given?
      yield petitions unless petitions.empty?
    else
      petitions
    end
  end

  def trending_petitions_at
    @trending_petitions_at ||= Time.at((Time.now.to_i / 60) * 60).in_time_zone
  end

  def fetch_trending_petitions(now, period, limit)
    signature_id = Signature.arel_table[:id]
    signature_count = signature_id.count.as("signature_count_in_period")
    Petition.trending(period.ago(now)..now, limit).pluck(:id, :action, signature_count)
  end
  private :fetch_trending_petitions
end
