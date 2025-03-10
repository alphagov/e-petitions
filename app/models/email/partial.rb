require 'textacular/searchable'

module Email
  class Partial < ActiveRecord::Base
    extend Searchable(:name, :content)
    include Browseable

    NORMALIZE_CONTENT = lambda do |content|
      content.tap do |c|
        c.encode!(universal_newline: true)
        c.gsub!(/ +$/, "")
        c.gsub!(/\b\s*\z/, "\n")
      end
    end

    normalizes :content, with: NORMALIZE_CONTENT

    NAME_REGEXP = /\A[a-z][-_a-z0-9]+\z/

    validates :name, presence: true, length: { maximum: 50 }
    validates :name, uniqueness: true, format: { with: NAME_REGEXP }
    validates :content, presence: true, length: { maximum: 10000 }

    facet :all, -> { by_name }

    class << self
      def for(name, &block)
        find_or_initialize_by(name: name).tap(&block)
      end

      def by_name
        order(:name)
      end
    end

    def dump
      [name, content]
    end
  end
end
