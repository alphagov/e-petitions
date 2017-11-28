class AddIndexToSignatureConstituencyId < ActiveRecord::Migration[4.2]
  def change
    add_index :signatures, :constituency_id
  end
end
