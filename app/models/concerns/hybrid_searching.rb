module HybridSearching
  extend ActiveSupport::Concern

  included do
    class_attribute :embedding_column, instance_writer: false, default: :embedding
    class_attribute :textsearch_columns, instance_writer: false, default: %i[action background additional_details]
  end

  module ClassMethods
    def hybrid_search(query, distance: nil)
      embedding = Embedding.generate(query)

      relation = where(hybrid_query(query, embedding, distance: distance))
      relation.reorder(arel_table[embedding_column].nearest(embedding))
    end

    private

    def hybrid_query(query, embedding, distance: nil)
      parameters = {
        distance: distance || Site.semantic_search_threshold,
        query: query,
        embedding: type_caster.type_cast_for_database(embedding_column, embedding)
      }

      [hybrid_sql, parameters]
    end

    def hybrid_sql
      @hybrid_sql ||= build_hybrid_sql
    end

    def build_hybrid_sql
      sql = textsearch_columns.map { |column| build_tsvector_condition(column) }
      sql << build_pgvector_condition(embedding_column)

      sql.join(" OR ")
    end

    def build_tsvector_condition(column)
      "(to_tsvector('english', #{quoted_table_name}.#{quoted_column(column)}) @@ plainto_tsquery('english', :query))"
    end

    def build_pgvector_condition(column)
      "(#{quoted_table_name}.#{quoted_column(column)} <=> :embedding < :distance)"
    end

    def quoted_column(column)
      connection.quote_column_name(column)
    end
  end
end
