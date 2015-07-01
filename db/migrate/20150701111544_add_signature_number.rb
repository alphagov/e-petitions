class AddSignatureNumber < ActiveRecord::Migration
  def change
    add_column :signatures, :number, :integer
  end
end
