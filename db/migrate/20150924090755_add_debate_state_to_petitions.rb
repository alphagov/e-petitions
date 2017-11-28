class AddDebateStateToPetitions < ActiveRecord::Migration[4.2]
  def change
    add_column :petitions, :debate_state, :string, limit: 30, default: 'pending'
  end
end
