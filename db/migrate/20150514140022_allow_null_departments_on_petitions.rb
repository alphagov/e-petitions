class AllowNullDepartmentsOnPetitions < ActiveRecord::Migration
  def change
    change_column_null :petitions, :department_id, true
  end
end
