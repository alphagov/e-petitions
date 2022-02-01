class AddPetitionMailshotTimestamps < ActiveRecord::Migration[6.1]
  def up
    unless column_exists?(:email_requested_receipts, :petition_mailshot)
      add_column :email_requested_receipts, :petition_mailshot, :datetime
    end

    unless column_exists?(:archived_petitions, :email_requested_for_petition_mailshot_at)
      add_column :archived_petitions, :email_requested_for_petition_mailshot_at, :datetime
    end

    unless column_exists?(:archived_signatures, :petition_mailshot_at)
      add_column :archived_signatures, :petition_mailshot_at, :datetime
    end

    unless column_exists?(:signatures, :petition_mailshot_at)
      add_column :signatures, :petition_mailshot_at, :datetime
    end
  end

  def down
    if column_exists?(:email_requested_receipts, :petition_mailshot)
      remove_column :email_requested_receipts, :petition_mailshot, :datetime
    end

    if column_exists?(:archived_petitions, :email_requested_for_petition_mailshot_at)
      remove_column :archived_petitions, :email_requested_for_petition_mailshot_at, :datetime
    end

    if column_exists?(:archived_signatures, :petition_mailshot_at)
      remove_column :archived_signatures, :petition_mailshot_at, :datetime
    end

    if column_exists?(:signatures, :petition_mailshot_at)
      remove_column :signatures, :petition_mailshot_at, :datetime
    end
  end
end
