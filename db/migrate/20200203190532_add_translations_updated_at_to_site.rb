class AddTranslationsUpdatedAtToSite < ActiveRecord::Migration[5.2]
  def change
    add_column :sites, :translations_updated_at, :timestamp
  end
end
