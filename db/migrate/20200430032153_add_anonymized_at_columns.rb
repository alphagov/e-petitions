class AddAnonymizedAtColumns < ActiveRecord::Migration[5.2]
  disable_ddl_transaction!

  def change
    add_column :signatures, :anonymized_at, :datetime
    add_index :signatures, [:anonymized_at, :petition_id], algorithm: :concurrently

    add_column :petitions, :anonymized_at, :datetime
    add_index :petitions, :anonymized_at, algorithm: :concurrently
  end
end
