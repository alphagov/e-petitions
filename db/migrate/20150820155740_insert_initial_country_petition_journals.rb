class InsertInitialCountryPetitionJournals < ActiveRecord::Migration[4.2]
  def up
    execute <<-SQL.strip_heredoc
      INSERT INTO country_petition_journals
        (petition_id, country, signature_count, created_at, updated_at)
      SELECT
        petition_id, country, COUNT(*) AS signature_count,
        timezone('utc', now()), timezone('utc', now())
      FROM signatures
      GROUP BY petition_id, country
    SQL
  end

  def down
    execute "DELETE FROM country_petition_journals"
  end
end
