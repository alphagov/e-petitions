# Fix Rails bug with quoting nodes
ActiveSupport.on_load(:active_record) do
  module Arel
    module Predications
      def contains(other)
        Arel::Nodes::Contains.new(self, quoted_node(other))
      end

      def overlaps(other)
        Arel::Nodes::Overlaps.new(self, quoted_node(other))
      end
    end
  end
end
