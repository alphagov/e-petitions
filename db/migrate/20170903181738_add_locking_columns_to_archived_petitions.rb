class AddLockingColumnsToArchivedPetitions < ActiveRecord::Migration[4.2]
  def change
    add_column :archived_petitions, :locked_at, :datetime
    add_column :archived_petitions, :locked_by_id, :integer

    add_index :archived_petitions, :locked_by_id
  end
end
