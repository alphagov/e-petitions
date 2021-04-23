class AddIndexOnClosedAtToPetitions < ActiveRecord::Migration[6.1]
  disable_ddl_transaction!

  def up
    execute <<~SQL
      CREATE INDEX CONCURRENTLY IF NOT EXISTS
      index_petitions_on_closed_at ON petitions (closed_at DESC);
    SQL
  end

  def down
    execute <<~SQL
      DROP INDEX CONCURRENTLY IF EXISTS
      index_petitions_on_closed_at;
    SQL
  end
end
