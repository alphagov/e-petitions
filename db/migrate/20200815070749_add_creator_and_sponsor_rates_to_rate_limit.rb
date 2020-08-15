class AddCreatorAndSponsorRatesToRateLimit < ActiveRecord::Migration[5.2]
  class RateLimit < ActiveRecord::Base; end

  def change
    add_column :rate_limits, :creator_rate, :integer
    add_column :rate_limits, :sponsor_rate, :integer

    up_only do
      RateLimit.update_all(creator_rate: 2, sponsor_rate: 5)

      change_column_null :rate_limits, :creator_rate, false
      change_column_null :rate_limits, :sponsor_rate, false

      change_column_default :rate_limits, :creator_rate, 2
      change_column_default :rate_limits, :sponsor_rate, 5
    end
  end
end
