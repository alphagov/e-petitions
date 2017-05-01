class AddUuidToSignatures < ActiveRecord::Migration
  def change
    add_column :signatures, :uuid, :uuid
    add_index :signatures, :uuid
  end
end
