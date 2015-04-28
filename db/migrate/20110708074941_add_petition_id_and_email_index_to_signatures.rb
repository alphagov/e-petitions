class AddPetitionIdAndEmailIndexToSignatures < ActiveRecord::Migration
  def self.up
    add_index :signatures, [:petition_id, :email]
  end

  def self.down
    remove_index :signatures, [:petition_id, :email]
  end
end
