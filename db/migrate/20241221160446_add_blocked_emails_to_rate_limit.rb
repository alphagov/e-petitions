class AddBlockedEmailsToRateLimit < ActiveRecord::Migration[7.2]
  def change
    add_column :rate_limits, :blocked_emails, :string, limit: 50000, null: false, default: ""
  end
end
