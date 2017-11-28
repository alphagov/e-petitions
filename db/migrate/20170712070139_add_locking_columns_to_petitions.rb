class AddLockingColumnsToPetitions < ActiveRecord::Migration[4.2]
  def change
    add_column :petitions, :locked_at, :datetime
    add_column :petitions, :locked_by_id, :integer

    add_index :petitions, :locked_by_id
  end
end
