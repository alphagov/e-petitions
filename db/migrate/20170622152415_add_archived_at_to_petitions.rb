class AddArchivedAtToPetitions < ActiveRecord::Migration[4.2]
  def change
    add_column :petitions, :archived_at, :datetime
  end
end
