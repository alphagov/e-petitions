class AddConstituencyIdToSignatures < ActiveRecord::Migration
  def change
    add_column :signatures, :constituency_id, :string
  end
end
