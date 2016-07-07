class IncreaseSizeOfSignatureState < ActiveRecord::Migration
  def up
    change_column :signatures, :state, :string, limit: 20, null: false, default: 'pending'
  end

  def down
    change_column :signatures, :state, :string, limit: 10, null: false, default: 'pending'
  end
end
