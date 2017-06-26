class UpdateArchivedPetitionIndexes < ActiveRecord::Migration[4.2]
  def up
    execute <<-SQL
      CREATE INDEX index_archived_petitions_on_action
      ON archived_petitions USING gin(to_tsvector('english', action));
    SQL

    execute <<-SQL
      CREATE INDEX index_archived_petitions_on_background
      ON archived_petitions USING gin(to_tsvector('english', background));
    SQL

    execute <<-SQL
      CREATE INDEX index_archived_petitions_on_additional_details
      ON archived_petitions USING gin(to_tsvector('english', additional_details));
    SQL
  end

  def down
    execute "DROP INDEX index_archived_petitions_on_action;"
    execute "DROP INDEX index_archived_petitions_on_background;"
    execute "DROP INDEX index_archived_petitions_on_additional_details;"
  end
end
