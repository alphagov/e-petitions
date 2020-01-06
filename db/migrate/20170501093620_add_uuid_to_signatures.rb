class AddUuidToSignatures < ActiveRecord::Migration[4.2]
  def change
    add_column :signatures, :uuid, :uuid
    add_index :signatures, :uuid
  end
end
