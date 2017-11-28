class AddDebateScheduledToEmailSentReceipt < ActiveRecord::Migration[4.2]
  def change
    add_column :email_sent_receipts, :debate_scheduled, :timestamp
  end
end
