class AddEmailCountToSignatures < ActiveRecord::Migration[4.2]
  def change
    add_column :signatures, :email_count, :integer, null: false, default: 0
  end
end
