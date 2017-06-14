module Taggable
  extend ActiveSupport::Concern

  included do
    validates :tags, format: { with: /\A\[.*\]\z/, message: "must be type of Array or empty string" }, allow_nil: false
  end

  class_methods do
    # Assumes that base model implements a 'tags' array column. Being this
    # opinionated keeps the codebase simpler.

    def with_all_tags(tags)
      where("array_lowercase(tags) @> ARRAY[?]::varchar[]", downcase_tags(tags))
    end

    def with_tag(tag)
      where("'#{tag}' = ANY (array_lowercase(tags))")
    end

    def all_tags(options={}, &block)
      subquery_scope = unscoped.select("unnest(#{table_name}.tags) as tag").distinct
      subquery_scope = subquery_scope.instance_eval(&block) if block

      from(subquery_scope).pluck('tag')
    end

    def taggable?
      true
    end

    private

    def downcase_tags(tags)
      tags.map(&:downcase)
    end
  end

  def tags=(tags)
    if tags.kind_of?(String) && !tags.blank?
      string_tags = tags.each_line.map { |tag| "\"#{tag.strip}\"" }
      raise TypeError, "All strings are converted to an empty tags array. Are you sure you didn't mean [#{string_tags.join(', ')}]?"
    end

    tags = tags.reject(&:blank?) unless tags.blank?
    super
  end
end
