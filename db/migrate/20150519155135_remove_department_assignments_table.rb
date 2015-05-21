class RemoveDepartmentAssignmentsTable < ActiveRecord::Migration
  def change
    drop_table :department_assignments
  end
end
