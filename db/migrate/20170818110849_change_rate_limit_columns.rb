class ChangeRateLimitColumns < ActiveRecord::Migration
  def change
    rename_column(:rate_limits, :domain_whitelist, :allowed_domains)
    rename_column(:rate_limits, :ip_whitelist, :allowed_ips)
    rename_column(:rate_limits, :domain_blacklist, :blocked_domains)
    rename_column(:rate_limits, :ip_blacklist, :blocked_ips)
  end
end
