class AddArchivedAtIndexToPetitions < ActiveRecord::Migration[5.2]
  disable_ddl_transaction!

  def up
    unless index_exists?(:petitions, [:archived_at, :state])
      add_index :petitions, [:archived_at, :state], algorithm: :concurrently
    end
  end

  def down
    if index_exists?(:petitions, [:archived_at, :state])
      remove_index :petitions, [:petition_id, :state]
    end
  end
end
