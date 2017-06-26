class AddIndexOnDebateOutcomeUpdatedAt < ActiveRecord::Migration[4.2]
  def change
    add_index :debate_outcomes, :updated_at
  end
end
