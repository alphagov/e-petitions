module NearestNeighbours
  extend ActiveSupport::Concern

  module ClassMethods
    def nearest_neighbours(embedding, column: :embedding)
      reorder(arel_table[column].nearest(embedding))
    end
  end

  def nearest_neighbours(column: :embedding)
    self.class.excluding(self).nearest_neighbours(read_attribute(column), column: column)
  end
end
