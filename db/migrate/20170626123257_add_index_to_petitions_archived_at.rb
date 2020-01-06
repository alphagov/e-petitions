class AddIndexToPetitionsArchivedAt < ActiveRecord::Migration[4.2]
  disable_ddl_transaction!

  def up
    unless index_exists?(:petitions, :archived_at)
      add_index :petitions, :archived_at, algorithm: :concurrently
    end
  end

  def down
    if index_exists?(:petitions, :archived_at)
      remove_index :petitions, :archived_at
    end
  end
end
