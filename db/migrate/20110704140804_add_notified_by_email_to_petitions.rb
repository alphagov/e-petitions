class AddNotifiedByEmailToPetitions < ActiveRecord::Migration
  def self.up
    add_column :petitions, :notified_by_email, :boolean, :default => false
  end

  def self.down
    remove_column :petitions, :notified_by_email
  end
end
