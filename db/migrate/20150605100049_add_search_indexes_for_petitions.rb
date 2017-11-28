class AddSearchIndexesForPetitions < ActiveRecord::Migration[4.2]
  def up
    execute <<-SQL
      CREATE INDEX index_petitions_on_title
      ON petitions USING gin(to_tsvector('english', title));
    SQL

    execute <<-SQL
      CREATE INDEX index_petitions_on_action
      ON petitions USING gin(to_tsvector('english', description));
    SQL

    execute <<-SQL
      CREATE INDEX index_petitions_on_description
      ON petitions USING gin(to_tsvector('english', description));
    SQL
  end

  def down
    execute "DROP INDEX index_petitions_on_title;"
    execute "DROP INDEX index_petitions_on_action;"
    execute "DROP INDEX index_petitions_on_description;"
  end
end
