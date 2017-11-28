class AddSignatureCountIntervalToSites < ActiveRecord::Migration[4.2]
  def change
    add_column :sites, :signature_count_interval, :integer, null: false, default: 60
  end
end
