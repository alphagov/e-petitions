class AddIndexToPetitionDebateState < ActiveRecord::Migration[4.2]
  def change
    add_index :petitions, :debate_state
  end
end
