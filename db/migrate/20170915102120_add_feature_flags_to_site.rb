class AddFeatureFlagsToSite < ActiveRecord::Migration
  def change
    add_column :sites, :feature_flags, :jsonb, default: {}, null: false
  end
end
