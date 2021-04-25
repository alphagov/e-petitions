class OptimizeSearchIndexesForInvalidations < ActiveRecord::Migration[6.1]
  disable_ddl_transaction!

  def up
    execute <<~SQL
      CREATE INDEX CONCURRENTLY IF NOT EXISTS
      index_invalidations_for_search
      ON invalidations USING gin((
        to_tsvector('english', summary::text) ||
        to_tsvector('english', COALESCE(details)::text) ||
        to_tsvector('english', COALESCE(petition_id)::text)
      ));
    SQL

    execute "DROP INDEX CONCURRENTLY IF EXISTS ft_index_invalidations_on_details"
    execute "DROP INDEX CONCURRENTLY IF EXISTS ft_index_invalidations_on_id"
    execute "DROP INDEX CONCURRENTLY IF EXISTS ft_index_invalidations_on_petition_id"
    execute "DROP INDEX CONCURRENTLY IF EXISTS ft_index_invalidations_on_summary"
    execute "ANALYZE invalidations"
  end

  def down
    execute <<~SQL
      CREATE INDEX CONCURRENTLY IF NOT EXISTS ft_index_invalidations_on_details
      ON invalidations USING gin(to_tsvector('english', details::text));
    SQL

    execute <<~SQL
      CREATE INDEX CONCURRENTLY IF NOT EXISTS ft_index_invalidations_on_id
      ON invalidations USING gin(to_tsvector('english', id::text));
    SQL

    execute <<~SQL
      CREATE INDEX CONCURRENTLY IF NOT EXISTS ft_index_invalidations_on_petition_id
      ON invalidations USING gin(to_tsvector('english', petition_id::text));
    SQL

    execute <<~SQL
      CREATE INDEX CONCURRENTLY IF NOT EXISTS ft_index_invalidations_on_summary
      ON invalidations USING gin(to_tsvector('english', summary::text));
    SQL

    execute "DROP INDEX CONCURRENTLY IF EXISTS index_invalidations_for_search"
    execute "ANALYZE invalidations"
  end
end
