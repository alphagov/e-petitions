class CreatePrivacyNotifications < ActiveRecord::Migration[6.1]
  def change
    create_table :privacy_notifications, id: false do |t|
      t.primary_key :id, :uuid, null: false, default: nil
      t.datetime :created_at, null: false
      t.datetime :updated_at, null: false
    end
  end
end
