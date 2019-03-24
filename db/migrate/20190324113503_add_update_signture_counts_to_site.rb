class AddUpdateSigntureCountsToSite < ActiveRecord::Migration
  def change
    add_column :sites, :update_signature_counts, :boolean, null: false, default: false
  end
end
