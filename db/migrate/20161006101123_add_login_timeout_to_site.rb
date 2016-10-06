class AddLoginTimeoutToSite < ActiveRecord::Migration
  def change
    add_column :sites, :login_timeout, :integer, null: false, default: 1800
  end
end
