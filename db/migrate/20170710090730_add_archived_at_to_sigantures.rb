class AddArchivedAtToSigantures < ActiveRecord::Migration
  def change
    add_column :signatures, :archived_at, :datetime
  end
end
