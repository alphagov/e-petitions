class AddStateAndUpdatedAtIndexToSignature < ActiveRecord::Migration
  def self.up
    add_index :signatures, :updated_at
    add_index :signatures, :state
  end

  def self.down
    remove_index :signatures, :updated_at
    remove_index :signatures, :state
  end
end
