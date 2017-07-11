class AddArchivedAtToSigantures < ActiveRecord::Migration
  def up
    unless column_exists?(:signatures, :archived_at)
      add_column :signatures, :archived_at, :datetime
    end
  end

  def down
    if column_exists?(:signatures, :archived_at)
      remove_column :signatures, :archived_at
    end
  end
end
