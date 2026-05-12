module NearestNeighbours
  extend ActiveSupport::Concern

  module ClassMethods
    def nearest_neighbours(embedding, column: :embedding, distance: nil)
      distance ||= Site.semantic_search_threshold
      relevance = arel_table[column].nearest(embedding)

      where(relevance.lt(distance))
    end

    def by_relevance(embedding, column: :embedding)
      reorder(arel_table[column].nearest(embedding))
    end

    def semantic_search(query, column: :embedding, distance: nil)
      distance ||= Site.semantic_search_threshold
      embedding = Embedding.generate(query)
      relevance = arel_table[column].nearest(embedding)

      where(relevance.lt(distance)).reorder(relevance)
    end
  end

  def nearest_neighbours(column: :embedding)
    self.class.excluding(self).nearest_neighbours(read_attribute(column), column: column)
  end
end
