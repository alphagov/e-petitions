class AddTrendingIpConfigToRateLimit < ActiveRecord::Migration[4.2]
  def change
    add_column :rate_limits, :enable_logging_of_trending_ips, :boolean, null: false, default: false
    add_column :rate_limits, :threshold_for_logging_trending_ip, :integer, null: false, default: 100
    add_column :rate_limits, :threshold_for_notifying_trending_ip, :integer, null: false, default: 200
    add_column :rate_limits, :trending_ip_notification_url, :string
  end
end
