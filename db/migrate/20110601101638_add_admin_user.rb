class AddAdminUser < ActiveRecord::Migration
  def self.up
    create_table :admin_users, :force => true do |t|
      t.string   :email, :null => false
      t.string   :persistence_token
      t.string   :crypted_password
      t.string   :password_salt
      t.integer  :login_count, :default => 0  
      t.integer  :failed_login_count, :default => 0
      t.datetime :current_login_at
      t.datetime :last_login_at
      t.string   :current_login_ip
      t.string   :last_login_ip
      t.string   :first_name
      t.string   :last_name
      t.string   :role, :limit => 10, :null => false
      t.boolean  :force_password_reset, :default => true
      t.datetime :password_changed_at
      t.timestamps
    end
    
    add_index :admin_users, [:email], :unique => true
    add_index :admin_users, [:last_name, :first_name]
  end

  def self.down
    drop_table :admin_users
  end
end
