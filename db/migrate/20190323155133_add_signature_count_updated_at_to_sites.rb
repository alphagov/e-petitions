class AddSignatureCountUpdatedAtToSites < ActiveRecord::Migration
  def change
    add_column :sites, :signature_count_updated_at, :datetime
  end
end
