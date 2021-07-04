module Browseable
  extend ActiveSupport::Concern

  VALID_PAGE = /\A[1-9][0-9]{0,4}\z/
  VALID_PAGE_SIZE = /\A(?:[1-9]|[1-5][0-9])\z/

  included do
    class_attribute :facet_definitions, instance_writer: false
    self.facet_definitions = {}

    class_attribute :filter_definitions, instance_writer: false
    self.filter_definitions = {}

    class_attribute :query_columns, instance_writer: false
    self.query_columns = []

    class_attribute :default_page_size, instance_writer: false
    self.default_page_size = 50

    class_attribute :max_page_size, instance_writer: false
    self.max_page_size = 50
  end

  class Facets
    include Enumerable

    attr_reader :klass, :filters

    delegate :facet_definitions, to: :klass
    delegate :key?, :has_key?, :keys, to: :facet_definitions

    def initialize(klass, filters)
      @klass, @filters = klass, filters
    end

    def [](key)
      facet_counts[key]
    end

    def each(&block)
      keys.each do |key|
        yield key, self[key]
      end
    end

    def slice(*only_these_keys)
      only_these_keys.each_with_object({}) do |key, hash|
        hash[key] = self[key] if has_key?(key)
      end
    end

    private

    def facet_counts
      @facet_counts ||= Hash.new(&facet_count_query)
    end

    def facet_count_query
      lambda do |hash, key|
        unless facet_definitions.key?(key)
          raise ArgumentError, "Unsupported facet: #{key.inspect}"
        end

        hash[key] = facet_scope(key).count
      end
    end

    def facet_scope(key)
      filters.apply(klass).instance_exec(&facet_definitions.fetch(key))
    end
  end

  class Filters
    attr_reader :klass, :params
    delegate :filter_definitions, to: :klass

    def initialize(klass, params)
      @klass = klass

      @params = \
        case params
        when ActionController::Parameters
          params.to_unsafe_hash
        when Hash
          params
        else
          raise ArgumentError, "Expected params to be a Hash or a ActionController::Parameters but was a #{params.class}"
        end
    end

    def apply(relation)
      filter_params.each do |key, value|
        relation = relation.instance_exec(value, &filter_definitions[key.to_sym])
      end

      relation
    end

    def to_hash
      params.slice(*filter_keys)
    end

    private

    def filter_keys
      @filter_keys ||= filter_definitions.keys
    end

    def filter_params
      params.slice(*filter_keys)
    end
  end

  class Query
    Column = Struct.new(:name, :config, :null)

    attr_reader :klass, :param

    delegate :query_columns, to: :klass
    delegate :connection, to: :klass
    delegate :quoted_table_name, to: :klass
    delegate :quote_column_name, to: :connection
    delegate :inspect, :present?, :==, to: :to_s

    def initialize(klass, param)
      @klass, @param = klass, param.to_s
    end

    def build
      unless query_columns.empty?
        [sql, query: param]
      end
    end

    def to_s
      param
    end

    private

    def sql
      "((#{search_conditions.join(" || ")}) @@ #{to_tsquery})"
    end

    def search_conditions
      query_columns.map(&method(:search_condition))
    end

    def search_condition(column)
      "#{to_tsvector(column)}"
    end

    def quoted_column(column)
      quoted_table_name + "." + quote_column_name(column)
    end

    def to_tsvector(column)
      if column.null
        "to_tsvector('#{column.config}', COALESCE(#{quoted_column(column.name)}, '')::text)"
      else
        "to_tsvector('#{column.config}', #{quoted_column(column.name)}::text)"
      end
    end

    def to_tsquery
      "plainto_tsquery('english', :query)"
    end
  end

  class Search
    include Enumerable

    attr_reader :klass, :params

    delegate :default_page_size, :max_page_size, to: :klass
    delegate :offset, :out_of_bounds?, to: :results
    delegate :next_page, :previous_page, to: :results
    delegate :total_entries, :total_pages, to: :results
    delegate :to_a, :to_ary, to: :results
    delegate :each, :map, :size, to: :to_a
    delegate :explain, to: :execute_search_with_pagination

    def initialize(klass, params = {})
      @klass, @params = klass, params
    end

    def current_page
      @current_page ||= [sanitized_page, 1].max
    end

    def find_each(&block)
      execute_search.find_each(&block)
    end

    def facets
      @facets ||= Facets.new(klass, filters)
    end

    def filters
      @filters ||= Filters.new(klass, params)
    end

    def empty?
      total_entries.zero?
    end

    def first_page?
      current_page <= 1
    end

    def second_page?
      current_page == 2
    end

    def last_page?
      current_page >= total_pages
    end

    def query
      @query ||= Query.new(klass, params[:q])
    end

    def page_size
      @page_size ||= [[sanitized_page_size, max_page_size].min, 1].max
    end

    def previous_params
      new_params(previous_page)
    end

    def next_params
      new_params(next_page)
    end

    def current_params
      new_params(current_page)
    end

    def facet_params(facet, options = {})
      {}.tap do |new_params|
        new_params[:state] = facet
        new_params.merge!(filters)
        new_params.merge!(options)
      end
    end

    def scope
      @scope ||= facets.keys.detect(-> { :all }){ |key| key.to_s == params[:state] }
    end

    def scoped?
      scope != :all
    end

    def search?
      query.present?
    end

    def in_batches(&block)
      execute_search.find_each do |obj|
        block.call obj
      end
    end

    def inspect
      [].tap do |parts|
        parts << "#<#{self.class.name}:#{object_id}"
        parts << " class: #{klass.klass.to_s.inspect}"
        parts << " scope: #{scope.to_s.inspect}" if scoped?
        parts << " query: #{query.inspect}" if search?
        parts << " size: #{total_entries}"
        parts << ">"
      end.join
    end

    def model
      klass.klass
    end

    private

    def new_params(page)
      {}.tap do |new_params|
        new_params[:q] = query if query.present?
        new_params[:state] = scope
        new_params[:page] = page
        new_params[:count] = page_size if params.key?(:count)
        new_params.merge!(filters)
      end
    end

    def results
      @results ||= execute_search_with_pagination
    end

    def execute_search_with_pagination
      execute_search.paginate(page: current_page, per_page: page_size)
    end

    def execute_search
      if search?
        relation = klass.where(query.build)
      else
        relation = klass
      end

      relation = filters.apply(relation)
      relation.instance_exec(&klass.facet_definitions[scope])
    end

    def star
      klass.arel_table[Arel.star]
    end

    def sanitize_param(value, pattern, default)
      value.match?(pattern) ? Integer(value) : default
    end

    def sanitized_page
      sanitize_param(params[:page].to_s, VALID_PAGE, 1)
    end

    def sanitized_page_size
      sanitize_param(params[:count].to_s, VALID_PAGE_SIZE, default_page_size)
    end
  end

  module ClassMethods
    def facet(key, scope)
      self.facet_definitions[key] = scope
    end

    def filter(key, transformer)
      self.filter_definitions[key] = transformer
    end

    def query(*columns, config: "english", null: false)
      self.query_columns += columns.map { |column| Query::Column.new(column.to_s, config, null) }
    end

    def search(params)
      Search.new(all, params)
    end
  end
end
