class CreateRateLimits < ActiveRecord::Migration[4.2]
  def change
    create_table :rate_limits do |t|
      t.integer :burst_rate, null: false, default: 1
      t.integer :burst_period, null: false, default: 60
      t.integer :sustained_rate, null: false, default: 5
      t.integer :sustained_period, null: false, default: 300
      t.string  :domain_whitelist, null: false, limit: 10000, default: ""
      t.string  :ip_whitelist, null: false, limit: 10000, default: ""
      t.timestamps null: false
    end
  end
end
