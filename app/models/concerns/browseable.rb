module Browseable
  extend ActiveSupport::Concern

  included do
    class_attribute :facet_definitions, instance_writer: false
    self.facet_definitions = {}

    class_attribute :filter_definitions, instance_writer: false
    self.filter_definitions = []
  end

  class Facets
    include Enumerable

    attr_reader :klass

    delegate :facet_definitions, to: :klass
    delegate :key?, :has_key?, :keys, to: :facet_definitions

    def initialize(klass)
      @klass = klass
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
      klass.instance_exec(&facet_definitions.fetch(key))
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

    def to_hash
      params.slice(*filter_definitions)
    end
  end

  class Search
    include Enumerable

    attr_reader :klass, :params

    delegate :offset, :out_of_bounds?, to: :results
    delegate :next_page, :previous_page, to: :results
    delegate :total_entries, :total_pages, to: :results
    delegate :each, :empty?, :map, :to_a, to: :results

    def initialize(klass, params = {})
      @klass, @params = klass, params
    end

    def current_page
      @current_page ||= [params[:page].to_i, 1].max
    end

    def each(&block)
      results.each(&block)
    end

    def find_each(&block)
      execute_search.find_each(&block)
    end

    def facets
      @facets ||= Facets.new(klass)
    end

    def filters
      @filters ||= Filters.new(klass, params)
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
      @query ||= params[:q].to_s
    end

    def page_size
      @page_size ||= [[params.fetch(:count, 50).to_i, 50].min, 1].max
    end

    def previous_params
      new_params(previous_page)
    end

    def next_params
      new_params(next_page)
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

    def to_a
      results.to_a
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
      {}.tap do |params|
        params[:q] = query if query.present?
        params[:state] = scope
        params[:page] = page
        params.merge!(filters)
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
        relation = klass.basic_search(query)
        relation = relation.except(:select).select(star)
        relation = relation.except(:order)
      else
        relation = klass
      end

      relation.instance_exec(&klass.facet_definitions[scope])
    end

    def star
      klass.arel_table[Arel.star]
    end
  end

  module ClassMethods
    def facet(key, scope)
      self.facet_definitions[key] = scope
    end

    def filter(key)
      self.filter_definitions << key
    end

    def search(params)
      Search.new(all, params)
    end
  end
end
