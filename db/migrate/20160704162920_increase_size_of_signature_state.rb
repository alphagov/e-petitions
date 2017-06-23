class IncreaseSizeOfSignatureState < ActiveRecord::Migration[4.2]
  def up
    change_column :signatures, :state, :string, limit: 20, null: false, default: 'pending'
  end

  def down
    change_column :signatures, :state, :string, limit: 10, null: false, default: 'pending'
  end
end
