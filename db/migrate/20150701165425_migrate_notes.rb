class MigrateNotes < ActiveRecord::Migration[4.2]
  def up
    execute <<-SQL
      INSERT INTO notes
        (petition_id, details, created_at, updated_at)
      SELECT
        id, admin_notes, updated_at, updated_at
      FROM
        petitions
      WHERE
        admin_notes IS NOT NULL
    SQL

    remove_column :petitions, :admin_notes
  end

  def down
    add_column :petitions, :admin_notes, :text

    execute <<-SQL
      UPDATE petitions AS p SET
        admin_notes = n.details
      FROM
        notes AS n
      WHERE
        p.id = n.petition_id
    SQL
  end
end
