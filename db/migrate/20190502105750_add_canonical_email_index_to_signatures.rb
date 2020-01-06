class AddCanonicalEmailIndexToSignatures < ActiveRecord::Migration[4.2]
  disable_ddl_transaction!

  def up
    unless index_exists?(:signatures, :canonical_email)
      add_index :signatures, :canonical_email, algorithm: :concurrently
    end
  end

  def down
    if index_exists?(:signatures, :canonical_email)
      remove_index :signatures, :canonical_email
    end
  end
end
