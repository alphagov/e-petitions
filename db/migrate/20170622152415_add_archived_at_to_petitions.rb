class AddArchivedAtToPetitions < ActiveRecord::Migration
  def change
    add_column :petitions, :archived_at, :datetime
  end
end
