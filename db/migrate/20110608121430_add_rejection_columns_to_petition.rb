class AddRejectionColumnsToPetition < ActiveRecord::Migration
  def self.up
    add_column :petitions, :rejection_reason, :string
    add_column :petitions, :rejection_text, :text
    add_column :petitions, :is_hidden, :boolean, :default => false
  end

  def self.down
    remove_column :petitions, :rejection_reason
    remove_column :petitions, :rejection_text
    remove_column :petitions, :is_hidden
  end
end
