class AddLocationCodeToSignatures < ActiveRecord::Migration[4.2]
  def change
    add_column :signatures, :location_code, :string, limit: 30
  end
end
