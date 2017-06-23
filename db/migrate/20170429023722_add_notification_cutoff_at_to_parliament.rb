class AddNotificationCutoffAtToParliament < ActiveRecord::Migration[4.2]
  def change
    add_column :parliaments, :notification_cutoff_at, :datetime
  end
end
