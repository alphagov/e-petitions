class AddArchivingStartedAtToParliaments < ActiveRecord::Migration[4.2]
  def change
    add_column :parliaments, :archiving_started_at, :datetime
  end
end
