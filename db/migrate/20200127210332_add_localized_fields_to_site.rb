class AddLocalizedFieldsToSite < ActiveRecord::Migration[5.2]
  def change
    rename_column :sites, :title, :title_en
    rename_column :sites, :url, :url_en
    rename_column :sites, :email_from, :email_from_en

    add_column :sites, :title_cy, :string, limit: 50, default: "Senedd ddeiseb", null: false
    add_column :sites, :url_cy, :string, limit: 50, default: "https://deiseb.senedd.cymru", null: false
    add_column :sites, :email_from_cy, :string, limit: 100, default: "\"Deisebau: Llywodraeth a Senedd Cymru\" <dim-ateb@deiseb.senedd.cymru>", null: false
  end
end
