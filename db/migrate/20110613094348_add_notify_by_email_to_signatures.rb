class AddNotifyByEmailToSignatures < ActiveRecord::Migration
  def self.up
    add_column :signatures, :notify_by_email, :boolean
  end

  def self.down
    remove_column :signatures, :notify_by_email
  end
end
