class AddBlacklistToRateLimits < ActiveRecord::Migration
  def change
    add_column :rate_limits, :domain_blacklist, :string, null: false, limit: 50000, default: ""
    add_column :rate_limits, :ip_blacklist, :string, null: false, limit: 50000, default: ""
  end
end
