class AddAdminUsersDepartments < ActiveRecord::Migration
  def self.up
    create_table :admin_users_departments, :id => false do |t|
      t.integer :admin_user_id, :null => false
      t.integer :department_id, :null => false
    end
    add_index :admin_users_departments, [:admin_user_id, :department_id], :unique => true, :name => 'index_admin_users_departments_on_fks'
    add_index :admin_users_departments, [:department_id]
  end

  def self.down
    drop_table :admin_users_departments
  end
end
