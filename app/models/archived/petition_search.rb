module Archived
  class PetitionSearch
    include Enumerable
    include Search

    self.model = Archived::Petition

    self.permitted_params = [
      :keyword, :state, :q, :query, :page, :count, :sort, :parliament,
      parliament: [], status: [], response: [], debate: []
    ]

    mapping :all, sort: "popular"
    mapping :published, status: %w[closed], sort: "popular", parliament: -> { Parliament.last_archived_id }
    mapping :rejected, status: %w[rejected], sort: "recent"
    mapping :with_response, status: %w[closed], response: %w[responded], sort: "popular"
    mapping :debated, status: %w[closed], debate: %w[debated], sort: "latest_debate"
    mapping :not_debated, status: %w[open closed], debate: %w[not_debated], sort: "latest_debate"

    parameter :query, default: ""
    alias_attribute :q, :query

    filter :parliament, default: [], values: -> { Parliament.archived_ids }
    filter :status, default: [], values: %w[closed rejected]
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
        I18n.t(:"archived_petitions.search.sorting.semantic_menu")
      else
        I18n.t(:"archived_petitions.search.sorting.menu")
      end
    end

    def sorting_description
      if semantic_search?
        I18n.t(sort, scope: :"archived_petitions.search.sorting.semantic_descriptions")
      else
        I18n.t(sort, scope: :"archived_petitions.search.sorting.descriptions")
      end
    end

    def parliaments
      @parliaments ||= Parliament.archive_menu
    end

    def parliament_map
      @parliament_map ||= parliaments.map { |period, id| [id.to_s, "#{period} Parliament"] }.to_h
    end

    def selected_filter(key, value)
      if key == :parliament
        parliament_map.fetch(value)
      else
        I18n.t(value, scope: :"archived_petitions.search.filters.#{key}")
      end
    end

    private

    def relation
      super.preload(:creator, :rejection, :government_response, :debate_outcome)
    end

    def parliament_for_execute(scope)
      parliament.empty? ? scope : scope.where(parliament_id: parliament)
    end

    def status_for_execute(scope)
      if status.empty?
        scope.where(state: %w[closed rejected])
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
end
