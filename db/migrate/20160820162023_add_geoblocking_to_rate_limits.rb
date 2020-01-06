class AddGeoblockingToRateLimits < ActiveRecord::Migration[4.2]
  def change
    add_column :rate_limits, :geoblocking_enabled, :boolean, null: false, default: false
  end
end
