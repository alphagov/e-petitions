class AddDebatedToDebateOutcome < ActiveRecord::Migration
  def change
    add_column :debate_outcomes, :debated, :boolean, null: false, default: true
  end
end
