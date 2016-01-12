class Domain < ActiveRecord::Base
  class Log < ActiveRecord::Base
    validates_presence_of :name
    validates_length_of :name, maximum: 255
    validates_format_of :name, with: /\A([a-z0-9]+(-[a-z0-9]+)*\.)*[a-z]{2,}\z/

    before_create :create_parent, unless: :top_level?

    class << self
      def current(at, size)
        group(:name).where(starting(at - size)).where(ending(at))
      end

      def stale(at)
        where(ending(at))
      end

      private

      def starting(at)
        arel_table[:created_at].gteq(at)
      end

      def ending(at)
        arel_table[:created_at].lt(at)
      end
    end

    private

    def create_parent
      self.class.create(name: parent_name)
    end

    def parent_name
      if defined?(@parent_name)
        @parent_name
      else
        @parent_name = name.partition('.').last.presence
      end
    end

    def top_level?
      parent_name.nil?
    end
  end
end
