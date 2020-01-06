class AddLastRequestAtToAdminUsers < ActiveRecord::Migration[4.2]
  def change
    add_column :admin_users, :last_request_at, :datetime
  end
end
