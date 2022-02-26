class AddTimeToPrivacyNotifications < ActiveRecord::Migration[6.1]
  def change
    add_column :privacy_notifications, :ignore_petitions_before, :datetime, null: false
  end
end
