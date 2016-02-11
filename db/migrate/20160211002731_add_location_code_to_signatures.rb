class AddLocationCodeToSignatures < ActiveRecord::Migration
  def change
    add_column :signatures, :location_code, :string, limit: 30
  end
end
