class AddForeignKeyToCountryJournals < ActiveRecord::Migration[5.2]
  def change
    add_foreign_key "country_petition_journals", "petitions", on_delete: :cascade
  end
end
