class MigrateGovernmentResponses < ActiveRecord::Migration[4.2]
  def up
    execute <<-SQL
      INSERT INTO government_responses
        (petition_id, summary, details, created_at, updated_at)
      SELECT
        id, response_summary, response,
        government_response_at, government_response_at
      FROM
        petitions
      WHERE
        government_response_at IS NOT NULL
    SQL

    remove_column :petitions, :response
    remove_column :petitions, :response_summary
  end

  def down
    add_column :petitions, :response, :text
    add_column :petitions, :response_summary, :string, limit: 500

    execute <<-SQL
      UPDATE petitions AS p SET
        response_summary = r.summary,
        response = r.details
      FROM
        government_responses AS r
      WHERE
        p.id = r.petition_id
    SQL
  end
end
