class OptimizeSearchIndexesForTopics < ActiveRecord::Migration[6.1]
  disable_ddl_transaction!

  def up
    execute <<~SQL
      CREATE INDEX CONCURRENTLY IF NOT EXISTS
      index_topics_for_search
      ON topics USING gin((
        to_tsvector('english', code::text) ||
        to_tsvector('english', name::text)
      ));
    SQL

    execute "ANALYZE topics"
  end

  def down
    execute "DROP INDEX CONCURRENTLY IF EXISTS index_topics_for_search"
    execute "ANALYZE topics"
  end
end
