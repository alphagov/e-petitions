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

  def limited_results_for_create_petition_search
    execute_search_for_create_petition_query.results
  end

  def result_count_for_state(state)
    @facets ||= petition_result_counts.facet(:state).rows
    default = -> { NullFacet.new }
    @facets.find(default) { |f| f.value.to_s == state }.count
  end

  private

  def search_term_sanitised
    @search_term_sanitised ||= construct_search_string(search_term)
  end

  def petitions
    @petitions ||= execute_search_query
  end

  def petition_result_counts
    @petition_result_counts ||= execute_result_counts_query
  end

  def execute_search_query
    Petition.search do |query|
      query.fulltext search_term_sanitised
      query.paginate page: @params[:page], per_page: 20
      case state
      when State::CLOSED_STATE
        query.with(:state).equal_to("open")
        query.with(:closed_at).less_than(Time.current.utc)
      when State::REJECTED_STATE
        query.with(:state).equal_to("rejected")
      when State::OPEN_STATE
        query.with(:state).equal_to("open")
        query.with(:closed_at).greater_than(Time.current.utc)
      end
      query.order_by *SearchOrder.sort_order(@params, [:score, :desc])
    end
  end

  def execute_search_for_create_petition_query
    Petition.search do |query|
      query.fulltext search_term_sanitised
      query.paginate page: 1, per_page: 3
      query.with(:state, ['open', 'rejected'])
      query.order_by *SearchOrder.sort_order(@params, [:score, :desc])
    end
  end

  def execute_result_counts_query
    Petition.search do |query|
      query.fulltext search_term_sanitised
      query.facet(:state) do
        row(:open) do
          with(:state).equal_to("open")
          with(:closed_at).greater_than(Time.current.utc)
        end
        row(:closed) do
          with(:state).equal_to("open")
          with(:closed_at).less_than(Time.current.utc)
        end
        row(:rejected) do
          with(:state).equal_to("rejected")
        end
      end
    end
  end

  def construct_search_string(keywords)
    remove_star_and_backslashes(keywords).split.first(10).collect do |word|
      keyword_string(word)
    end.join(" ")
  end

  def remove_star_and_backslashes(keywords)
    keywords.gsub('*', ' ').gsub('\\', ' ')
  end

  def keyword_string(word)
    escape_special_characters(word)
    word
  end

  LUCENE_SPECIAL_CHARS = %w(- && || ! ( ) { } [ ] ^ " ~ ? :)

  # see Escaping Special Characters
  # http://lucene.apache.org/java/2_9_1/queryparsersyntax.html#Escaping+Special+Characters
  def escape_special_characters(word)
    LUCENE_SPECIAL_CHARS.each do |c|
      word.gsub!(c, "\\#{c}")
    end

    # need to use a block since doing gsub without a block with a '+' doesn't work
    word.gsub!('+') {|m| '\+'}
  end
end
