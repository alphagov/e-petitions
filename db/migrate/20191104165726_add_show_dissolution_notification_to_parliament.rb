class AddShowDissolutionNotificationToParliament < ActiveRecord::Migration[4.2]
  def change
    add_column :parliaments, :show_dissolution_notification, :boolean, null: false, default: false
  end
end
