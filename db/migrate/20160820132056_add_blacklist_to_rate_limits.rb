class AddBlacklistToRateLimits < ActiveRecord::Migration[4.2]
  def change
    add_column :rate_limits, :domain_blacklist, :string, null: false, limit: 50000, default: ""
    add_column :rate_limits, :ip_blacklist, :string, null: false, limit: 50000, default: ""
  end
end
