class AddIndexToPetitionDebateState < ActiveRecord::Migration
  def change
    add_index :petitions, :debate_state
  end
end
