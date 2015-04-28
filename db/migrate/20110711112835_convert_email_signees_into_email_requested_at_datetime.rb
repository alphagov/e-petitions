class ConvertEmailSigneesIntoEmailRequestedAtDatetime < ActiveRecord::Migration
  def self.up
    remove_column :petitions, :email_signees
    add_column :petitions, :email_requested_at, :datetime
  end

  def self.down
    add_column :petitions, :email_signees, :boolean
    remove_column :petitions, :email_requested_at
  end
end
