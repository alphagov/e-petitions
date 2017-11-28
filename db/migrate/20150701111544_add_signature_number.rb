class AddSignatureNumber < ActiveRecord::Migration[4.2]
  def change
    add_column :signatures, :number, :integer
  end
end
