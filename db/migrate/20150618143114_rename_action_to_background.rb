class RenameActionToBackground < ActiveRecord::Migration[4.2]
  def change
    rename_column :petitions, :action, :background
    reversible do |dir|
      dir.up do
        remove_index :petitions, name: 'index_petitions_on_action'
        execute <<-SQL
          CREATE INDEX index_petitions_on_background
          ON petitions USING gin(to_tsvector('english', background));
        SQL
      end
      dir.down do
        remove_index :petitions, name: 'index_petitions_on_background'
        execute <<-SQL
          CREATE INDEX index_petitions_on_action
          ON petitions USING gin(to_tsvector('english', action));
        SQL
      end
    end
  end
end
