class ChangeDepartmentsDescriptionToTextField < ActiveRecord::Migration
  def self.up
    change_column :departments, :description, :text
  end

  def self.down
    change_column :departments, :description, :string
  end
end
