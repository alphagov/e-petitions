class RemoveDepartmentFromPetitions < ActiveRecord::Migration
  def change
    remove_column :petitions, :department_id, :integer
  end
end
