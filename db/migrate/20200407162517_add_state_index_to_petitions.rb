class AddStateIndexToPetitions < ActiveRecord::Migration[5.2]
  disable_ddl_transaction!

  def up
    unless index_exists?(:petitions, [:state, :debate_state])
      add_index :petitions, [:state, :debate_state], algorithm: :concurrently
    end
  end

  def down
    if index_exists?(:petitions, [:state, :debate_state])
      remove_index :petitions, [:state, :debate_state]
    end
  end
end
