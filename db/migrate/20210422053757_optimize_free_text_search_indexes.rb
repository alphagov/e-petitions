class OptimizeFreeTextSearchIndexes < ActiveRecord::Migration[6.1]
  disable_ddl_transaction!

  def up
    execute "CREATE EXTENSION IF NOT EXISTS btree_gin"

    execute <<~SQL
      CREATE INDEX CONCURRENTLY IF NOT EXISTS
      index_petitions_for_search
      ON petitions USING gin((
        to_tsvector('english', id::text) ||
        to_tsvector('english', action::text) ||
        to_tsvector('english', background::text) ||
        to_tsvector('english', COALESCE(additional_details, '')::text)),
        state, debate_state
      );
    SQL

    execute <<~SQL
      CREATE INDEX CONCURRENTLY IF NOT EXISTS
      index_archived_petitions_for_search
      ON archived_petitions USING gin((
        to_tsvector('english', id::text) ||
        to_tsvector('english', action::text) ||
        to_tsvector('english', background::text) ||
        to_tsvector('english', COALESCE(additional_details, '')::text)),
        state, parliament_id, debate_state
      );
    SQL

    execute "DROP INDEX CONCURRENTLY IF EXISTS index_petitions_on_action"
    execute "DROP INDEX CONCURRENTLY IF EXISTS index_petitions_on_background"
    execute "DROP INDEX CONCURRENTLY IF EXISTS index_petitions_on_additional_details"
    execute "ANALYZE petitions"

    execute "DROP INDEX CONCURRENTLY IF EXISTS index_archived_petitions_on_action"
    execute "DROP INDEX CONCURRENTLY IF EXISTS index_archived_petitions_on_background"
    execute "DROP INDEX CONCURRENTLY IF EXISTS index_archived_petitions_on_additional_details"
    execute "ANALYZE archived_petitions"
  end

  def down
    execute <<~SQL
      CREATE INDEX CONCURRENTLY IF NOT EXISTS
      index_petitions_on_action
      ON petitions USING gin(
        to_tsvector('english', action)
      );
    SQL

    execute <<~SQL
      CREATE INDEX CONCURRENTLY IF NOT EXISTS
      index_petitions_on_background
      ON petitions USING gin(
        to_tsvector('english', background)
      );
    SQL

    execute <<~SQL
      CREATE INDEX CONCURRENTLY IF NOT EXISTS
      index_petitions_on_additional_details
      ON petitions USING gin(
        to_tsvector('english', additional_details)
      );
    SQL

    execute <<~SQL
      CREATE INDEX CONCURRENTLY IF NOT EXISTS
      index_archived_petitions_on_action
      ON archived_petitions USING gin(
        to_tsvector('english', action)
      );
    SQL

    execute <<~SQL
      CREATE INDEX CONCURRENTLY IF NOT EXISTS
      index_archived_petitions_on_background
      ON archived_petitions USING gin(
        to_tsvector('english', background)
      );
    SQL

    execute <<~SQL
      CREATE INDEX CONCURRENTLY IF NOT EXISTS
      index_archived_petitions_on_additional_details
      ON archived_petitions USING gin(
        to_tsvector('english', additional_details)
      );
    SQL

    execute "DROP INDEX CONCURRENTLY IF EXISTS index_petitions_for_search"
    execute "ANALYZE petitions"

    execute "DROP INDEX CONCURRENTLY IF EXISTS index_archived_petitions_for_search"
    execute "ANALYZE archived_petitions"

    execute "DROP EXTENSION IF EXISTS btree_gin"
  end
end
