class CreateCountryPetitionJournals < ActiveRecord::Migration[4.2]
  def change
    create_table :country_petition_journals do |t|
      t.references :petition, null: false
      t.string :country, null: false
      t.integer :signature_count, default: 0, null: false

      t.timestamps null: false
    end

    add_index :country_petition_journals, [:petition_id, :country], unique: true
  end
end
