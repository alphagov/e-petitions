class AddConstituencyIdToSignatures < ActiveRecord::Migration[4.2]
  def change
    add_column :signatures, :constituency_id, :string
  end
end
