class AddTrendingItemsToRateLimits < ActiveRecord::Migration[4.2]
  def up
    add_column :rate_limits, :enable_logging_of_trending_items, :boolean, null: false, default: false
    add_column :rate_limits, :threshold_for_logging_trending_items, :integer, null: false, default: 100
    add_column :rate_limits, :threshold_for_notifying_trending_items, :integer, null: false, default: 200
    add_column :rate_limits, :trending_items_notification_url, :string

    execute <<-SQL
      UPDATE rate_limits SET
        enable_logging_of_trending_items = enable_logging_of_trending_ips,
        threshold_for_logging_trending_items = threshold_for_logging_trending_ip,
        threshold_for_notifying_trending_items = threshold_for_notifying_trending_ip,
        trending_items_notification_url = trending_ip_notification_url
    SQL
  end

  def down
    remove_column :rate_limits, :enable_logging_of_trending_items
    remove_column :rate_limits, :threshold_for_logging_trending_items
    remove_column :rate_limits, :threshold_for_notifying_trending_items
    remove_column :rate_limits, :trending_items_notification_url
  end
end
