class OptimizeSearchIndexesForDepartments < ActiveRecord::Migration[6.1]
  disable_ddl_transaction!

  def up
    execute <<~SQL
      CREATE INDEX CONCURRENTLY IF NOT EXISTS
      index_departments_for_search
      ON departments USING gin((
        to_tsvector('english', name::text) ||
        to_tsvector('english', COALESCE(acronym, '')::text)
      ));
    SQL

    execute "ANALYZE departments"
  end

  def down
    execute "DROP INDEX CONCURRENTLY IF EXISTS index_departments_for_search"
    execute "ANALYZE departments"
  end
end
