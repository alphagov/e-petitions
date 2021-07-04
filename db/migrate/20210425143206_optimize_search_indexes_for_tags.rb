class OptimizeSearchIndexesForTags < ActiveRecord::Migration[6.1]
  disable_ddl_transaction!

  def up
    execute <<~SQL
      CREATE INDEX CONCURRENTLY IF NOT EXISTS
      index_tags_for_search
      ON tags USING gin((
        to_tsvector('english', name::text) ||
        to_tsvector('english', COALESCE(description)::text)
      ));
    SQL

    execute "DROP INDEX CONCURRENTLY IF EXISTS index_ft_tags_on_name"
    execute "DROP INDEX CONCURRENTLY IF EXISTS index_ft_tags_on_description"
    execute "ANALYZE tags"
  end

  def down
    execute <<~SQL
      CREATE INDEX CONCURRENTLY IF NOT EXISTS index_ft_tags_on_name
      ON tags USING gin(to_tsvector('english', name));
    SQL

    execute <<~SQL
      CREATE INDEX CONCURRENTLY IF NOT EXISTS index_ft_tags_on_description
      ON tags USING gin(to_tsvector('english', description));
    SQL

    execute "DROP INDEX CONCURRENTLY IF EXISTS index_tags_for_search"
    execute "ANALYZE tags"
  end
end
