class AddSignatureCountUpdatedAtToSites < ActiveRecord::Migration[4.2]
  def change
    add_column :sites, :signature_count_updated_at, :datetime
  end
end
