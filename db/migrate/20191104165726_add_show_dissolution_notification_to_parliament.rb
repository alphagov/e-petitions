class AddShowDissolutionNotificationToParliament < ActiveRecord::Migration
  def change
    add_column :parliaments, :show_dissolution_notification, :boolean, null: false, default: false
  end
end
