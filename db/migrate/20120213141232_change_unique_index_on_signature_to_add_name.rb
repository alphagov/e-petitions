class ChangeUniqueIndexOnSignatureToAddName < ActiveRecord::Migration
  def self.up
    remove_index :signatures, [:email, :petition_id]
    add_index :signatures, [:email, :petition_id, :name], :unique => true
  end

  def self.down
    remove_index :signatures, [:email, :petition_id, :name]
    add_index :signatures, [:email, :petition_id], :unique => true
  end
end
