class AddOptimizedSearchIndexes < ActiveRecord::Migration[6.1]
  disable_ddl_transaction!

  def up
    add_index :petitions, [:state, :open_at, :created_at],
      order: { open_at: :desc, created_at: :desc },
      if_not_exists: true, algorithm: :concurrently

    add_index :petitions, [:state, :signature_count, :created_at],
      order: { signature_count: :desc, created_at: :desc },
      if_not_exists: true, algorithm: :concurrently
  end

  def down
    remove_index :petitions, [:state, :open_at, :created_at],
      if_exists: true, algorithm: :concurrently

    remove_index :petitions, [:state, :signature_count, :created_at],
      if_exists: true, algorithm: :concurrently
  end
end
