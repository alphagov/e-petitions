class AddEmailResponseFlagToPetition < ActiveRecord::Migration
  def self.up
    change_column :petitions, :response, :text
    add_column :petitions, :email_signees, :boolean, :default => false
    add_index :petitions, :signature_count
    add_index :petitions, [:state, :created_at]
  end

  def self.down
    change_column :petitions, :response, :string
    remove_column :petitions, :email_signees
    remove_index :petitions, :signature_count
    remove_index :petitions, [:state, :created_at]
  end
end
