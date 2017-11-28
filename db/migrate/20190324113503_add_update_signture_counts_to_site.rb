class AddUpdateSigntureCountsToSite < ActiveRecord::Migration[4.2]
  def change
    add_column :sites, :update_signature_counts, :boolean, null: false, default: false
  end
end
