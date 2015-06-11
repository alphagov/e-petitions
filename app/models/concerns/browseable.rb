module Browseable
  extend ActiveSupport::Concern

  included do
    class_attribute :facets
    self.facets = {}
  end

  class Facets
    include Enumerable

    attr_reader :search, :klass

    def initialize(search)
      @search, @klass = search, search.klass
    end

    def [](key)
      facets[key]
    end

    def key?(key)
      facet?(key)
    end
    alias_method :has_key?, :key?

    def keys
      klass.facets.keys
    end

    def each(&block)
      keys.each do |key|
        yield key, self[key]
      end
    end

    private

    def facet(key)
      klass.facets.fetch(key)
    end

    def facet?(key)
      klass.facets.key?(key)
    end

    def facets
      @facets ||= Hash.new(&facet_query)
    end

    def facet_query
      lambda do |hash, key|
        unless facet?(key)
          raise ArgumentError, "Unsupported facet: #{key.inspect}"
        end

        hash[key] = scope(key).count
      end
    end

    def scope(key)
      search.klass.instance_exec(&facet(key))
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

    def facets
      @facets ||= Facets.new(self)
    end

    def first_page?
      current_page <= 1
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

    def scope
      @scope ||= facets.keys.detect{ |key| key.to_s == params[:state] }
    end

    def scoped?
      scope.present?
    end

    def search?
      query.present?
    end

    def to_a
      results.to_a
    end

    private

    def results
      @results ||= execute_search
    end

    def execute_search
      relation = klass.basic_search(query)
      relation = relation.except(:select).select(star)
      relation = relation.reorder(:created_at)

      if scoped?
        relation = relation.instance_exec(&klass.facets[scope])
      end

      relation.paginate(page: current_page, per_page: page_size)
    end

    def star
      klass.arel_table[Arel.star]
    end
  end

  module ClassMethods
    def facet(key, scope)
      self.facets[key] = scope
    end

    def search(params)
      Search.new(self, params)
    end
  end
end
