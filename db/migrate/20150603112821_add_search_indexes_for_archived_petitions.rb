class AddSearchIndexesForArchivedPetitions < ActiveRecord::Migration[4.2]
  def up
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

    execute <<-SQL
      CREATE INDEX index_archived_petitions_on_state_and_closed_at
      ON archived_petitions USING btree (state, closed_at);
    SQL

    execute <<-SQL
      CREATE INDEX index_archived_petitions_on_signature_count
      ON archived_petitions USING btree (signature_count);
    SQL
  end

  def down
    execute "DROP INDEX index_archived_petitions_on_title;"
    execute "DROP INDEX index_archived_petitions_on_description;"
    execute "DROP INDEX index_archived_petitions_on_state;"
    execute "DROP INDEX index_archived_petitions_on_signature_count;"
  end
end
