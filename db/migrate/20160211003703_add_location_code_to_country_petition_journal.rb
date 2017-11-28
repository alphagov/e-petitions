class AddLocationCodeToCountryPetitionJournal < ActiveRecord::Migration[4.2]
  def change
    add_column :country_petition_journals, :location_code, :string, limit: 30
    add_index :country_petition_journals, [:petition_id, :location_code], unique: true, name: 'index_country_petition_journals_on_petition_and_location'
    change_column_null :country_petition_journals, :country, true
  end
end
