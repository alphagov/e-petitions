class AddIndexToSignaturesArchivedAt < ActiveRecord::Migration[4.2]
  disable_ddl_transaction!

  def up
    unless index_exists?(:signatures, [:archived_at, :petition_id])
      add_index :signatures, [:archived_at, :petition_id], algorithm: :concurrently
    end
  end

  def down
    if index_exists?(:signatures, [:archived_at, :petition_id])
      remove_index :signatures, [:archived_at, :petition_id]
    end
  end
end
