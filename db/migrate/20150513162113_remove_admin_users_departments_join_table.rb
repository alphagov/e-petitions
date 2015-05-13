class RemoveAdminUsersDepartmentsJoinTable < ActiveRecord::Migration
  def change
    drop_table 'admin_users_departments'
  end
end
