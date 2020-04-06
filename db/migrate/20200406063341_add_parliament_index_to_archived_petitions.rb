class AddParliamentIndexToArchivedPetitions < ActiveRecord::Migration[5.2]
  disable_ddl_transaction!

  def up
    unless index_exists?(:archived_petitions, [:state, :parliament_id])
      add_index :archived_petitions, [:state, :parliament_id], algorithm: :concurrently
    end
  end

  def down
    if index_exists?(:archived_petitions, [:state, :parliament_id])
      remove_index :archived_petitions, [:state, :parliament_id]
    end
  end
end
