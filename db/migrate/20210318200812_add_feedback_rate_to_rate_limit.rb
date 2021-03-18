class AddFeedbackRateToRateLimit < ActiveRecord::Migration[5.2]
  class RateLimit < ActiveRecord::Base; end

  def change
    add_column :rate_limits, :feedback_rate, :integer

    up_only do
      RateLimit.update_all(feedback_rate: 2)

      change_column_null :rate_limits, :feedback_rate, false
      change_column_default :rate_limits, :feedback_rate, 2
    end
  end
end
