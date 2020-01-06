class AddTagsToPetitionsAndArchivedPetitions < ActiveRecord::Migration[4.2]
  def up
    add_column :petitions, :tags, :integer, array: true, null: false, default: "{}"
    add_column :archived_petitions, :tags, :integer, array: true, null: false, default: "{}"

    execute <<-SQL
      CREATE INDEX index_petitions_on_tags
      ON petitions USING gin(tags gin__int_ops);
    SQL

    execute <<-SQL
      CREATE INDEX index_archived_petitions_on_tags
      ON archived_petitions USING gin(tags gin__int_ops);
    SQL
  end

  def down
    execute "DROP INDEX index_petitions_on_tags;"
    execute "DROP INDEX index_archived_petitions_on_tags;"

    remove_column :petitions, :tags
    remove_column :archived_petitions, :tags
  end
end
