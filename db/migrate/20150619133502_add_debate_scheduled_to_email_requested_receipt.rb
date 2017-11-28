class AddDebateScheduledToEmailRequestedReceipt < ActiveRecord::Migration[4.2]
  def change
    add_column :email_requested_receipts, :debate_scheduled, :timestamp
  end
end
