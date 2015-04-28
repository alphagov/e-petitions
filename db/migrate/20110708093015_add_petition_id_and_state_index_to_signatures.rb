class AddPetitionIdAndStateIndexToSignatures < ActiveRecord::Migration
  def self.up
    add_index :signatures, [:petition_id, :state]
  end

  def self.down
    remove_index :signatures, [:petition_id, :state]
  end
end
