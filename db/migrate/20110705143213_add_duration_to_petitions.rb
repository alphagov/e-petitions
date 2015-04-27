class AddDurationToPetitions < ActiveRecord::Migration
  def self.up
    add_column :petitions, :duration, :string, :limit => 2, :default => "12"
  end

  def self.down
    remove_column :petitions, :duration
  end
end
