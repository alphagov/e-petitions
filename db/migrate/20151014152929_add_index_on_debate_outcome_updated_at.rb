class AddIndexOnDebateOutcomeUpdatedAt < ActiveRecord::Migration
  def change
    add_index :debate_outcomes, :updated_at
  end
end
