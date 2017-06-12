class AddArchivedAtToParliaments < ActiveRecord::Migration
  def change
    add_column :parliaments, :archived_at, :datetime
  end
end
