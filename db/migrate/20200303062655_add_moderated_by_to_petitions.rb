class AddModeratedByToPetitions < ActiveRecord::Migration[5.2]
  disable_ddl_transaction!

  def up
    unless column_exists?(:petitions, :moderated_by_id)
      add_column :petitions, :moderated_by_id, :integer
      add_index :petitions, :moderated_by_id, algorithm: :concurrently
      add_foreign_key :petitions, :admin_users, column: :moderated_by_id
    end
  end

  def down
    if column_exists?(:petitions, :moderated_by_id)
      remove_foreign_key :petitions, column: :moderated_by_id
      remove_index :petitions, :moderated_by_id
      remove_column :petitions, :moderated_by_id
    end
  end
end
