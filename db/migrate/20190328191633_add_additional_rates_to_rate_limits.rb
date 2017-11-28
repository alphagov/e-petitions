class AddAdditionalRatesToRateLimits < ActiveRecord::Migration[4.2]
  def change
    add_column :rate_limits, :country_burst_rate, :integer, null: false, default: 1
    add_column :rate_limits, :country_sustained_rate, :integer, null: false, default: 60
    add_column :rate_limits, :country_rate_limits_enabled, :boolean, null: false, default: false
  end
end
