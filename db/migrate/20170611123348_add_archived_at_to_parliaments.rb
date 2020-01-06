class AddArchivedAtToParliaments < ActiveRecord::Migration[4.2]
  def change
    add_column :parliaments, :archived_at, :datetime
  end
end
