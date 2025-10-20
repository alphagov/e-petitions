module Search
  extend ActiveSupport::Concern

  include ActiveModel::Model
  include ActiveModel::Attributes
  include ActiveModel::AttributeMethods
  include ActiveModel::Dirty
  include ActiveSupport::NumberHelper

  class EnumType < ActiveModel::Type::Value
    attr_reader :values

    def initialize(values:)
      @values = resolve(values).map(&:to_s)
    end

    def cast(value)
      return nil unless value.is_a?(String)
      return nil unless values.include?(value)

      value
    end

    private

    def resolve(values)
      values.respond_to?(:call) ? values.call : values
    end
  end

  class ListType < ActiveModel::Type::Value
    attr_reader :values

    def initialize(values:)
      @values = resolve(values).map(&:to_s)
    end

    def cast(value)
      Array(value).reject do |item|
        next true unless item.is_a?(String)
        next true if item.blank?
        next true unless values.include?(item)

        false
      end
    end

    private

    def resolve(values)
      values.respond_to?(:call) ? values.call : values
    end
  end

  included do
    with_options instance_writer: false do
      class_attribute :model
      class_attribute :permitted_params, default: []

      class_attribute :mappings, default: {}
      class_attribute :mapped_filters, default: Set[]

      class_attribute :filters, default: []
      class_attribute :scopes, default: []

      class_attribute :max_page, default: 10000
      class_attribute :default_page_size, default: 25
      class_attribute :min_page_size, default: 1
      class_attribute :max_page_size, default: 50
    end

    # Remove Enumerable#count method so we can use it as an attribute
    remove_possible_method :count

    attribute :state, :string
    attribute :page, :integer, default: 1
    attribute :count, :integer, default: -> { default_page_size }

    attribute_method_suffix "_for_execute"

    delegate :arel_table, to: :model

    delegate :offset, :out_of_bounds?, to: :results
    delegate :total_entries, :total_pages, to: :results
    delegate :to_a, :to_ary, to: :results
    delegate :each, :map, :size, :length, to: :to_a
  end

  class_methods do
    def mapping(state, **filters)
      self.mappings[state] = filters
      self.mapped_filters += filters.keys
    end

    def filter(name, values: [], default: nil)
      self.scopes << name
      self.filters << name

      attribute(name, ListType.new(values: values), default: default)
    end

    def parameter(name, values: [], default: nil)
      self.scopes << name

      if values.blank?
        attribute(name, :string, default: default)
      else
        attribute(name, EnumType.new(values: values), default: default)
      end
    end
  end

  def initialize(params = {})
    super(transform(permit(params)))
  end

  def empty?
    total_entries.zero?
  end

  def current_page
    @current_page ||= page > max_page ? 1 : page
  end

  def first_page
    new_page(1)
  end

  def first_page?
    current_page <= 1
  end

  def last_page
    new_page(total_pages)
  end

  def last_page?
    current_page >= total_pages
  end

  def previous_page
    new_page(page - 1)
  end

  def next_page
    new_page(page + 1)
  end

  def page_size
    @page_size ||= count.clamp(min_page_size, max_page_size)
  end

  def find_each(&block)
    execute_search.find_each(&block)
  end

  def selected_filters
    filters.flat_map do |name|
      public_send(name).map { |value| [name, value, excluding_filter(name, value)]}
    end
  end

  def current_params
    changed_params.map { |attribute| [attribute, public_send(attribute)] }.sort.to_h.compact_blank
  end

  def current_filters
    changed_filters.map { |attribute| [attribute, public_send(attribute)] }.sort.to_h.compact_blank
  end

  def clear_filter_params
    current_filters.excluding(:page, *filters)
  end

  def scope
    (state.presence || "all").to_sym
  end

  def search?
    query.present?
  end

  def semantic_search?
    embedding.present?
  end

  def formatted_total_entries
    number_to_delimited(total_entries)
  end

  def inspect
    [].tap do |parts|
      parts << "#<#{self.class.name}:#{object_id}"
      parts << " class: #{model.to_s.inspect}"
      parts << " size: #{total_entries}"
      parts << ">"
    end.join
  end

  private

  def transform(params)
    if state = params[:state]
      params.merge(mappings.fetch(state.to_sym, {}))
    else
      params
    end
  end

  def permit(params)
    case params
    when ActionController::Parameters
      params.permit(*permitted_params).to_h.symbolize_keys
    else
      params.to_h.symbolize_keys
    end
  end

  def changed_params
    if state_changed?
      changed.map(&:to_sym) - mapped_filters.to_a
    else
      changed.map(&:to_sym)
    end
  end

  def changed_filters
    changed.map(&:to_sym).without(:state)
  end

  def new_page(page)
    page = page.clamp(1, total_pages)

    if page == 1
      current_params.without(:page)
    else
      current_params.merge(page: page)
    end
  end

  def excluding_filter(name, value)
    current_filters.tap { |params| params[name] -= [value] }.compact_blank.excluding(:page)
  end

  def relation
    model.all
  end

  def embedding_column?
    model.column_names.include?("embedding")
  end

  def embedding
    return @embedding if defined?(@embedding)
    @embedding = generate_embedding
  end

  def generate_embedding
    return unless Site.semantic_searching?
    return unless query.present?
    return unless embedding_column?

    Embedding.generate(query)
  end

  def results
    @results ||= execute_search_with_pagination
  end

  def execute_search_with_pagination
    execute_search.paginate(page: current_page, per_page: page_size)
  end

  def execute_search
    scopes.inject(relation) do |scope, name|
      send(:"#{name}_for_execute", scope)
    end
  end

  def star
    arel_table[Arel.star]
  end

  def attribute_for_execute(name, scope)
    scope
  end
end
