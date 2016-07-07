class AddInvalidationColumnsToSignatures < ActiveRecord::Migration
  disable_ddl_transaction!

  def up
    unless column_exists?(:signatures, :invalidated_at)
      add_column :signatures, :invalidated_at, :datetime
    end

    unless column_exists?(:signatures, :invalidation_id)
      add_column :signatures, :invalidation_id, :integer
    end

    unless index_exists?(:signatures, :invalidation_id)
      add_index :signatures, :invalidation_id, algorithm: :concurrently
    end
  end

  def down
    if index_exists?(:signatures, :invalidation_id)
      remove_index :signatures, :invalidation_id
    end

    if column_exists?(:signatures, :invalidation_id)
      add_column :signatures, :invalidation_id, :datetime
    end

    if column_exists?(:signatures, :invalidated_at)
      add_column :signatures, :invalidated_at, :integer
    end
  end
end
