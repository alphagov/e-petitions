class AddClosedAtToPetitions < ActiveRecord::Migration
  def self.up
    add_column :petitions, :closed_at, :datetime
    execute "update petitions set closed_at = UTC_TIMESTAMP() + INTERVAL 1 YEAR where state = 'open'"
  end

  def self.down
    remove_column :petitions, :closed_at
  end
end
