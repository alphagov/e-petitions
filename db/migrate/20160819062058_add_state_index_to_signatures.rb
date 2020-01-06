class AddStateIndexToSignatures < ActiveRecord::Migration[4.2]
  disable_ddl_transaction!

  def up
    unless index_exists?(:signatures, [:state, :petition_id])
      add_index :signatures, [:state, :petition_id], algorithm: :concurrently
    end
  end

  def down
    if index_exists?(:signatures, [:state, :petition_id])
      remove_index :signatures, [:state, :petition_id]
    end
  end
end
