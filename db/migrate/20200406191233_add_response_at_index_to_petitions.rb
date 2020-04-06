class AddResponseAtIndexToPetitions < ActiveRecord::Migration[5.2]
  disable_ddl_transaction!

  def up
    unless index_exists?(:petitions, [:government_response_at, :state])
      add_index :petitions, [:government_response_at, :state], algorithm: :concurrently
    end
  end

  def down
    if index_exists?(:petitions, [:government_response_at, :state])
      remove_index :petitions, [:government_response_at, :state]
    end
  end
end
