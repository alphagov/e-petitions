module Taggable
  extend ActiveSupport::Concern

  included do
    class_attribute :tag_column
    self.tag_column = :tags
  end

  class_methods do
    def acts_as_taggable_array_on(*tag_def)
      self.tag_column = tag_def.first
    end

    def with_all_tags(tags)
      where("array_lowercase(#{tag_column}) @> ARRAY[?]::varchar[]", downcase_tags(tags))
    end

    def with_tag(tag)
      where("'#{tag.downcase}' = ANY (array_lowercase(#{tag_column}))")
    end

    def all_tags(options={}, &block)
      subquery_scope = unscoped.select("unnest(#{table_name}.#{tag_column}) as tag").distinct
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

  def tags_for_comparison
    tags.map(&:downcase)
  end
end
