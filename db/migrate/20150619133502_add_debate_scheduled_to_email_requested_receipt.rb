class AddDebateScheduledToEmailRequestedReceipt < ActiveRecord::Migration
  def change
    add_column :email_requested_receipts, :debate_scheduled, :timestamp
  end
end
