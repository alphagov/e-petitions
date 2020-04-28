class AddNewArchivedAtToPetitions < ActiveRecord::Migration[5.2]
  def change
    add_column :petitions, :archived_at, :datetime
  end
end
