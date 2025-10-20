module NearestNeighbours
  extend ActiveSupport::Concern

  module ClassMethods
    def relevance(embedding, column)
      arel_table[column].nearest(embedding)
    end

    def nearest_neighbours(embedding, column: :embedding, distance: 0.75)
      where(relevance(embedding, column).lt(distance))
    end

    def by_relevance(embedding, column: :embedding)
      reorder(relevance(embedding, column))
    end
  end

  def nearest_neighbours(column: :embedding)
    self.class.excluding(self).nearest_neighbours(read_attribute(column), column: column)
  end
end
