class SwitchDefaultOnNotifyByEmail < ActiveRecord::Migration
  def self.up
    change_column :signatures, :notify_by_email, :boolean, :default => false
  end

  def self.down
    change_column :signatures, :notify_by_email, :boolean, :default => true
  end
end
