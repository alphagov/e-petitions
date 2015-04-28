class ChangeRejectionReasonToRejectionCode < ActiveRecord::Migration
  def self.up
    add_column :petitions, :rejection_code, :string, :limit => 50
    execute "update petitions set rejection_code = rejection_reason"
    remove_column :petitions, :rejection_reason
  end

  def self.down
    add_column :petitions, :rejection_reason, :string
    execute "update petitions set rejection_reason = rejection_code"
    remove_column :petitions, :rejection_code
  end
end
