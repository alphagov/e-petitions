class AddPetitionEmailToEmailReceipts < ActiveRecord::Migration
  def change
    add_column :email_requested_receipts, :petition_email, :datetime
    add_column :email_sent_receipts, :petition_email, :datetime
  end
end
