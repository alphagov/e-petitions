class CreateDepartmentAssignments < ActiveRecord::Migration
  def self.up
    create_table :department_assignments do |t|
      t.references :petition
      t.references :department
      t.datetime   :assigned_on

      t.timestamps
    end
  end

  def self.down
    drop_table :department_assignments
  end
end
