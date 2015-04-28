class RemoveAddressAndTownFieldsFromSignature < ActiveRecord::Migration
  def self.up
    remove_column :signatures, :address
    remove_column :signatures, :town
  end

  def self.down
    add_column :signatures, :address, :string
    add_column :signatures, :town, :string
  end
end
