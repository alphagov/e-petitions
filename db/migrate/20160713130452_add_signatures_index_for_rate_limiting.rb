class AddSignaturesIndexForRateLimiting < ActiveRecord::Migration[4.2]
  disable_ddl_transaction!

  def up
    unless index_exists?(:signatures, [:created_at, :ip_address, :petition_id])
      add_index :signatures, [:created_at, :ip_address, :petition_id], algorithm: :concurrently
    end
  end

  def down
    if index_exists?(:signatures, [:created_at, :ip_address, :petition_id])
      remove_index :signatures, [:created_at, :ip_address, :petition_id]
    end
  end
end
