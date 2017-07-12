require 'active_support/concern'

module Taggable
  extend ActiveSupport::Concern

  included do
    validate :tags_exist
  end

  class_methods do
    def tagged_with_all(*tags)
      where(tags_column.contains(normalize_tags(tags)))
    end
    alias_method :tagged_with, :tagged_with_all

    def tagged_with_any(*tags)
      where(tags_column.overlaps(normalize_tags(tags)))
    end

    def untagged
      where(tags_column.eq([]))
    end

    def tags_column
      arel_table[:tags]
    end

    def normalize_tags(tags)
      Array(tags).flatten.map(&:to_i).compact.reject(&:zero?)
    end
  end

  def normalize_tags(tags)
    self.class.normalize_tags(tags)
  end

  def tags=(tags)
    super(normalize_tags(tags))
  end

  def tag_names
    Tag.where(id: tags).pluck(:name)
  end

  def tags_exist
    unless tags.all? { |tag| Tag.exists?(tag) }
      errors.add :tags, :invalid
    end
  end
end
