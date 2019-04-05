class AddTrendingIpDomainFilterToRateLimit < ActiveRecord::Migration
  def change
    add_column :rate_limits, :ignored_domains, :string, null: false, limit: 10000, default: ""
  end
end
