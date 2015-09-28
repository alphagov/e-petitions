class SetDebateStateOnPetitions < ActiveRecord::Migration
  def up
    execute <<-SQL
      UPDATE petitions SET debate_state = 'awaiting'
      WHERE debate_threshold_reached_at IS NOT NULL
      AND scheduled_debate_date IS NULL
    SQL

    execute <<-SQL
      UPDATE petitions SET debate_state = 'awaiting'
      WHERE scheduled_debate_date >= CURRENT_DATE
    SQL

    execute <<-SQL
      UPDATE petitions SET debate_state = 'debated'
      WHERE debate_outcome_at IS NOT NULL
    SQL

    execute <<-SQL
      UPDATE petitions SET debate_state = 'none'
      WHERE debate_outcome_at IS NOT NULL
      AND id IN (SELECT id FROM debate_outcomes WHERE debated = 'f')
    SQL

    execute <<-SQL
      UPDATE petitions SET debate_state = 'closed'
      WHERE state = 'closed'
      AND debate_threshold_reached_at IS NULL
      AND scheduled_debate_date IS NULL
      AND debate_outcome_at IS NULL
    SQL
  end

  def down
    Petition.update_all(debate_state: 'pending')
  end
end
