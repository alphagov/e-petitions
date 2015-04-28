class AddDefaultNotifyByEmailTrueToSignatures < ActiveRecord::Migration
  def self.up
    change_column :signatures, :notify_by_email, :boolean, :default => 1
  end

  def self.down
    change_column :signatures, :notify_by_email, :boolean, :default => nil
  end
end
