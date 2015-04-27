class DropIndexFromPetitions < ActiveRecord::Migration
  def self.up
    remove_index :petitions, :name => "petitions_by_closed_at"
  end

  def self.down
    add_index :petitions, [:department_id, :state, :closed_at], :name => "petitions_by_closed_at"
  end
end
