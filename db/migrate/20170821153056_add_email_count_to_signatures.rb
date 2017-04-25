class AddEmailCountToSignatures < ActiveRecord::Migration
  def change
    add_column :signatures, :email_count, :integer, null: false, default: 0
  end
end
