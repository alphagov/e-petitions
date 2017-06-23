class AddDebatedToDebateOutcome < ActiveRecord::Migration[4.2]
  def change
    add_column :debate_outcomes, :debated, :boolean, null: false, default: true
  end
end
