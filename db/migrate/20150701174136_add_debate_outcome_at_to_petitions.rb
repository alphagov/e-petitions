class AddDebateOutcomeAtToPetitions < ActiveRecord::Migration[4.2]
  def up
    add_column :petitions, :debate_outcome_at, :datetime

    execute <<-SQL
      UPDATE petitions AS p SET
        debate_outcome_at = d.created_at
      FROM
        debate_outcomes AS d
      WHERE
        p.id = d.petition_id
    SQL
  end

  def down
    remove_column :petitions, :debate_outcome_at
  end
end
