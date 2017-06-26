class AddLocationCodeIndexToCountryPetitionJournal < ActiveRecord::Migration[4.2]
  disable_ddl_transaction!

  def up
    unless index_exists?(:signatures, [:petition_id, :location_code])
      add_index :signatures, [:petition_id, :location_code], algorithm: :concurrently
    end
  end

  def down
    if index_exists?(:signatures, [:petition_id, :location_code])
      remove_index :signatures, [:petition_id, :location_code]
    end
  end
end
