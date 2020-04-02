require 'active_support/concern'

module Topics
  extend ActiveSupport::Concern

  CODE_PATTERN = /\A[a-z][-a-z0-9]*\z/

  included do
    validate :topics_exist
  end

  class_methods do
    def all_topics(*topics)
      where(topics_column.contains(normalize_topics(topics)))
    end
    alias_method :for_topic, :all_topics

    def topics(*codes)
      codes = normalize_topic_codes(codes)
      ids = Topic.where(code: codes).ids

      if codes.empty?
        all
      elsif ids.empty?
        none
      else
        where(topics_column.contains(ids))
      end
    end

    def any_topics(*topics)
      where(topics_column.overlaps(normalize_topics(topics)))
    end

    def with_topic
      where(topics_column.not_eq([]))
    end

    def without_topic
      where(topics_column.eq([]))
    end

    def topics_column
      arel_table[:topics]
    end

    def normalize_topics(topics)
      Array(topics).flatten.map(&:to_i).reject(&:zero?)
    end

    def normalize_topic_codes(codes)
      Array(codes).flatten.inject([]) do |codes, code|
        code = code.to_s.downcase.strip
        codes << code if code.match?(CODE_PATTERN)
        codes
      end
    end
  end

  def normalize_topics(topics)
    self.class.normalize_topics(topics)
  end

  def topics=(topics)
    super(normalize_topics(topics))
  end

  def topics_exist
    unless topics.all? { |topic| Topic.exists?(topic) }
      errors.add :topics, :invalid
    end
  end
end
