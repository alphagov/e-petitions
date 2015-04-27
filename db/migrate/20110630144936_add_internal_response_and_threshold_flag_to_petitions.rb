class AddInternalResponseAndThresholdFlagToPetitions < ActiveRecord::Migration
  def self.up
    add_column :petitions, :response_required, :boolean, :default => false
    add_column :petitions, :internal_response, :text
    remove_index :petitions, [:state]
    remove_index :petitions, [:signature_count]
    add_index :petitions, [:response_required, :signature_count]
  end

  def self.down
    add_index :petitions, [:state]
    add_index :petitions, [:signature_count]
    remove_index :petitions, [:response_required, :signature_count]
    remove_column :petitions, :response_required
    remove_column :petitions, :internal_response
  end
end
