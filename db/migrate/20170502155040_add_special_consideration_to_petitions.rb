class AddSpecialConsiderationToPetitions < ActiveRecord::Migration[4.2]
  def change
    add_column :petitions, :special_consideration, :boolean
  end
end
