class AddDebateScheduledToEmailSentReceipt < ActiveRecord::Migration
  def change
    add_column :email_sent_receipts, :debate_scheduled, :timestamp
  end
end
