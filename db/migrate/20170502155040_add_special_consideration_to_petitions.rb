class AddSpecialConsiderationToPetitions < ActiveRecord::Migration
  def change
    add_column :petitions, :special_consideration, :boolean
  end
end
