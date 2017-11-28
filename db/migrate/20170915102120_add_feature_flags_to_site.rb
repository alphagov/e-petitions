class AddFeatureFlagsToSite < ActiveRecord::Migration[4.2]
  def change
    add_column :sites, :feature_flags, :jsonb, default: {}, null: false
  end
end
