class DropLegacyArchiveIndexes < ActiveRecord::Migration[4.2]
  def up
    execute "DROP INDEX index_archived_petitions_on_title;"
    execute "DROP INDEX index_archived_petitions_on_description;"
  end

  def down
    execute <<-SQL
      CREATE INDEX index_archived_petitions_on_title
      ON archived_petitions
      USING gin(to_tsvector('english', title));
    SQL

    execute <<-SQL
      CREATE INDEX index_archived_petitions_on_description
      ON archived_petitions
      USING gin(to_tsvector('english', description));
    SQL
  end
end
