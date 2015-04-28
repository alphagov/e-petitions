class AddSignatureCountToPetition < ActiveRecord::Migration
  def self.up
    add_column :petitions, :signature_count, :integer, :default => 0
    add_index :petitions, [:state, :signature_count]
  end

  def self.down
    remove_index :petitions, [:state, :signature_count]
    remove_column :petitions, :signature_count
  end
end
