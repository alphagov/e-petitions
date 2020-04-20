class IncreaseIpAddressSize < ActiveRecord::Migration[5.2]
  def up
    change_column :invalidations, :ip_address, :string, limit: 40
    change_column :signatures, :ip_address, :string, limit: 40
  end

  def down
    change_column :invalidations, :ip_address, :string, limit: 20
    change_column :signatures, :ip_address, :string, limit: 20
  end
end
