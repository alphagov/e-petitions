class AddLastSignedAtToJournals < ActiveRecord::Migration[4.2]
  def up
    unless column_exists?(:constituency_petition_journals, :last_signed_at)
      add_column :constituency_petition_journals, :last_signed_at, :datetime
    end

    unless column_exists?(:country_petition_journals, :last_signed_at)
      add_column :country_petition_journals, :last_signed_at, :datetime
    end
  end

  def down
    if column_exists?(:constituency_petition_journals, :last_signed_at)
      remove_column :constituency_petition_journals, :last_signed_at
    end

    if column_exists?(:country_petition_journals, :last_signed_at)
      remove_column :country_petition_journals, :last_signed_at
    end
  end
end
