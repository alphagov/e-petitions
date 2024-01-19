class AddEmailCountToOtherParliamentaryBusinessArchived < ActiveRecord::Migration[6.1]
  def change
    add_column :archived_petition_emails, :email_count, :integer
    add_column :archived_petition_emails, :emails_enqueued_at, :datetime
  end
end
