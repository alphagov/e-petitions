class AddEmailCountToSignatures < ActiveRecord::Migration
  def change
    add_column :signatures, :email_count, :integer
  end
end
