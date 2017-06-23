class MigrateRejections < ActiveRecord::Migration[4.2]
  def up
    execute <<-SQL
      INSERT INTO rejections
        (petition_id, code, details, created_at, updated_at)
      SELECT
        id, rejection_code, rejection_text, updated_at, updated_at
      FROM
        petitions
      WHERE
        state = 'rejected'
    SQL

    add_column :petitions, :rejected_at, :datetime

    execute <<-SQL
      UPDATE petitions SET
        rejected_at = updated_at
      WHERE
        state = 'rejected'
    SQL

    remove_column :petitions, :rejection_code
    remove_column :petitions, :rejection_text
  end

  def down
    add_column :petitions, :rejection_code, :string, limit: 50
    add_column :petitions, :rejection_text, :text

    remove_column :petitions, :rejected_at

    execute <<-SQL
      UPDATE petitions AS p SET
        rejection_code = r.code,
        rejection_text = r.details
      FROM
        rejections AS r
      WHERE
        p.id = r.petition_id
    SQL
  end
end
