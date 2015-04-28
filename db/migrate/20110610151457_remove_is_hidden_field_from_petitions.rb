class RemoveIsHiddenFieldFromPetitions < ActiveRecord::Migration
  def self.up
    remove_column :petitions, :is_hidden
  end

  def self.down
    add_column :petitions, :is_hidden, :boolean, :default => false
  end
end
