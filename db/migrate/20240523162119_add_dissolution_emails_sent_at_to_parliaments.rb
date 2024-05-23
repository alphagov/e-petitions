class AddDissolutionEmailsSentAtToParliaments < ActiveRecord::Migration[7.1]
  def change
    add_column :parliaments, :dissolution_emails_sent_at, :datetime
  end
end
