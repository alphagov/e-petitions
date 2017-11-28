class AddCountriesToRateLimits < ActiveRecord::Migration[4.2]
  def change
    add_column :rate_limits, :countries, :string, limit: 2000, null: false, default: ""
  end
end
