class AddGeoblockingToRateLimits < ActiveRecord::Migration
  def change
    add_column :rate_limits, :geoblocking_enabled, :boolean, null: false, default: false
  end
end
