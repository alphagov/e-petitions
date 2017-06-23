class CleanupCountryColumns < ActiveRecord::Migration[4.2]
  def up
    # This migration commands have guard clauses because the preview
    # website executed a migration that was subsequently deleted
    # because of performance problems with it. Therefore to ensure
    # that the runs successfully on preview it needs these clauses.

    if index_exists?(:country_petition_journals, [:petition_id, :country])
      remove_index :country_petition_journals, [:petition_id, :country]
    end

    if column_exists?(:country_petition_journals, :country)
      remove_column :country_petition_journals, :country
    end

    if column_exists?(:signatures, :country)
      remove_column :signatures, :country
    end
  end

  def down
    add_column :signatures, :country, :string
    add_column :country_petition_journals, :country, :string
    add_index :country_petition_journals, [:petition_id, :country], unique: true
  end
end
