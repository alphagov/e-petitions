class Search
  attr_accessor :options

  def initialize(options = {})
    @options = options
    @options[:per_page] ||= 20
  end

  def state_counts_for(keywords)
    string = construct_search_string(keywords)
    rows = perform_search(string) do |sunspot|
      sunspot.facet(:state) do
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
    end.facet(:state).rows
    counts = Hash.new(0)
    rows.each do |row|
      counts[row.value.to_s] = row.count
    end
    counts
  end

  def execute(keywords)
    return nil unless State::SEARCHABLE_STATES.include?(options[:state])
    string = construct_search_string(keywords)
    unless string.empty?
      perform_search(string) do |sunspot|
        case options[:state]
        when State::CLOSED_STATE
          sunspot.with(:state).equal_to("open")
          sunspot.with(:closed_at).less_than(Time.zone.now.utc)
        when State::REJECTED_STATE
          sunspot.with(:state).equal_to("rejected")
        when State::OPEN_STATE
          sunspot.with(:state).equal_to("open")
          sunspot.with(:closed_at).greater_than(Time.zone.now.utc)
        end
      end
    else
      return nil
    end
  end

  private

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

  def perform_search(string)
    options[:sunspot_interface].search(options[:target]) do
      fulltext string
      adjust_solr_params do |params|
        params[:qf] = ''
        params[:defType] = ''
      end
      paginate(:page => options[:page], :per_page => options[:per_page])
      order_by *SearchOrder.sort_order(options, [:score, :desc])
      yield(self) if block_given?
    end
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
