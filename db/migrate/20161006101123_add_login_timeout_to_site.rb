class AddLoginTimeoutToSite < ActiveRecord::Migration[4.2]
  def change
    add_column :sites, :login_timeout, :integer, null: false, default: 1800
  end
end
