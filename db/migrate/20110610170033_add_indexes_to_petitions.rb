class AddIndexesToPetitions < ActiveRecord::Migration
  def self.up
    add_index :petitions, [:department_id, :state, :closed_at, :title], :name => 'petitions_by_title_closed_at'
    add_index :petitions, [:department_id, :state, :closed_at, :signature_count], :name => 'petitions_by_sig_count_closed_at'
    add_index :petitions, [:department_id, :state, :title], :name => 'petitions_by_title'
    add_index :petitions, [:department_id, :state, :signature_count], :name => 'petitions_by_sig_count'
    add_index :petitions, [:department_id, :state, :closed_at], :name => 'petitions_by_closed_at'
  end

  def self.down
    remove_index :petitions, :name => 'petitions_by_title_closed_at'
    remove_index :petitions, :name => 'petitions_by_sig_count_closed_at'
    remove_index :petitions, :name => 'petitions_by_title'
    remove_index :petitions, :name => 'petitions_by_sig_count'
    remove_index :petitions, :name => 'petitions_by_closed_at'
  end
end
