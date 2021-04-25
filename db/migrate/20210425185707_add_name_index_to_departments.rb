class AddNameIndexToDepartments < ActiveRecord::Migration[6.1]
  disable_ddl_transaction!

  def up
    add_index(:departments, :name, algorithm: :concurrently)
  end

  def down
    remove_index(:departments, :name, algorithm: :concurrently)
  end
end
