class AddArchivingStartedAtToParliaments < ActiveRecord::Migration
  def change
    add_column :parliaments, :archiving_started_at, :datetime
  end
end
