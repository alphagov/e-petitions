class RemoveIndexOnPerishableToken < ActiveRecord::Migration
  def self.up
    remove_index :signatures, :perishable_token
  end

  def self.down
    add_index :signatures, :perishable_token, :unique => true
  end
end
