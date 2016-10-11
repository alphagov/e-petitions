class AddLastRequestAtToAdminUsers < ActiveRecord::Migration
  def change
    add_column :admin_users, :last_request_at, :datetime
  end
end
