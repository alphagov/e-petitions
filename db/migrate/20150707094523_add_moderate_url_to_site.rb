class AddModerateUrlToSite < ActiveRecord::Migration
  def change
    add_column :sites, :moderate_url, :string, limit: 50, null: false, default: 'https://moderate.petition.parliament.uk'
  end
end
