class PetitionSearch
  include Enumerable
  include Search

  self.model = Petition

  self.permitted_params = [
    :keyword, :state, :q, :query, :page, :count, :sort,
    status: [], response: [], debate: []
  ]

  mapping :all, sort: "popular"
  mapping :open, status: %w[open], sort: "popular"
  mapping :recent, status: %w[open], sort: "recent"
  mapping :closed, status: %w[closed], sort: "popular"
  mapping :rejected, status: %w[rejected], sort: "recent"

  mapping :awaiting_response, status: %w[open closed],
    response: %w[awaiting], sort: "waiting_longest"

  mapping :with_response, status: %w[open closed],
    response: %w[responded], sort: "latest_response"

  mapping :awaiting_debate, status: %w[open closed],
    debate: %w[awaiting scheduled], sort: "upcoming_debates"

  mapping :debated, status: %w[open closed],
    debate: %w[debated], sort: "latest_debate"

  mapping :not_debated, status: %w[open closed],
    debate: %w[not_debated], sort: "latest_debate"

  parameter :query, default: ""
  alias_attribute :q, :query

  filter :status, default: [], values: %w[open closed rejected]
  filter :response, default: [], values: %w[responded awaiting]
  filter :debate, default: [], values: %w[debated not_debated awaiting scheduled]

  # Remove Enumerable#sort method so we can use it as an attribute
  remove_possible_method :sort

  parameter :sort, default: "default",
    values: %w[default popular recent waiting_longest latest_response upcoming_debates latest_debate]

  def sort
    super == "popular" && !semantic_search? ? "default" : super
  end

  def sortings
    if semantic_search?
      I18n.t(:"petitions.search.sorting.semantic_menu")
    else
      I18n.t(:"petitions.search.sorting.menu")
    end
  end

  def sorting_description
    if semantic_search?
      I18n.t(sort, scope: :"petitions.search.sorting.semantic_descriptions")
    else
      I18n.t(sort, scope: :"petitions.search.sorting.descriptions")
    end
  end

  def selected_filter(key, value)
    I18n.t(value, scope: :"petitions.search.filters.#{key}")
  end

  private

  def relation
    super.preload(:creator, :rejection, :government_response, :debate_outcome)
  end

  def status_for_execute(scope)
    if status.empty?
      scope.where(state: %w[open closed rejected])
    else
      scope.where(state: status)
    end
  end

  def response_for_execute(scope)
    response.empty? ? scope : scope.where(response_state: response)
  end

  def debate_for_execute(scope)
    debate.empty? ? scope : scope.where(debate_state: debate)
  end
end
