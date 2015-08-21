class AddIndexToSignatureConstituencyId < ActiveRecord::Migration
  def change
    add_index :signatures, :constituency_id
  end
end
