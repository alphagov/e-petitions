class AddNotificationCutoffAtToParliament < ActiveRecord::Migration
  def change
    add_column :parliaments, :notification_cutoff_at, :datetime
  end
end
