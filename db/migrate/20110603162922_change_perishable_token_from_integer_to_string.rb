class ChangePerishableTokenFromIntegerToString < ActiveRecord::Migration
  def self.up
    change_column :signatures, :perishable_token, :string
    add_index :signatures, :perishable_token, :unique => true
  end

  def self.down
    change_column :signatures, :perishable_token, :integer
    remove_index :signatures, :perishable_token
  end
end
