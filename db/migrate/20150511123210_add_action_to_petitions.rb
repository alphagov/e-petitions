class AddActionToPetitions < ActiveRecord::Migration
  def self.up
    add_column :petitions, :action, :string, limit: 200
  end

  def self.down
    remove_column :petitions, :action
  end  
end
