class PetitionSearch

  class NullFacet
    def count
     0
    end
  end

  def initialize(params)
    @params = params
  end

  def state
    State::SEARCHABLE_STATES.include?(@params[:state]) ? @params[:state] : 'open'
  end

  def search_term
   @params[:q] || ''
  end

  def results
    @results ||= petitions.results
  end

  def result_count_for_state(state)
    @facets ||= petition_result_counts.facet(:state).rows
    default = -> { NullFacet.new }
    @facets.find(default) { |f| f.value.to_s == state }.count
  end

  private

  def petitions
    @petitions ||= execute_search_query
  end

  def petition_result_counts
    @petition_result_counts ||= execute_result_counts_query
  end

  def execute_search_query
    Petition.search do |query|
      query.fulltext search_term
      query.facet :state
      query.paginate page: @params[:page], per_page: 20
      case state
      when State::CLOSED_STATE
        query.with(:state).equal_to("open")
        query.with(:closed_at).less_than(Time.zone.now.utc)
      when State::REJECTED_STATE
        query.with(:state).equal_to("rejected")
      when State::OPEN_STATE
        query.with(:state).equal_to("open")
        query.with(:closed_at).greater_than(Time.zone.now.utc)
      end
      query.order_by *SearchOrder.sort_order(@params, [:score, :desc])
    end
  end

  def execute_result_counts_query
    Petition.search do |query|
      query.fulltext search_term
      query.facet(:state) do
        row(:open) do
          with(:state).equal_to("open")
          with(:closed_at).greater_than(Time.zone.now.utc)
        end
        row(:closed) do
          with(:state).equal_to("open")
          with(:closed_at).less_than(Time.zone.now.utc)
        end
        row(:rejected) do
          with(:state).equal_to("rejected")
        end
      end
    end
  end
end
