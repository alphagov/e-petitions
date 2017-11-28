class AddTrendingIpDomainFilterToRateLimit < ActiveRecord::Migration[4.2]
  def change
    add_column :rate_limits, :ignored_domains, :string, null: false, limit: 10000, default: ""
  end
end
