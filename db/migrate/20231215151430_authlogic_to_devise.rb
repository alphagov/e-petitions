class AuthlogicToDevise < ActiveRecord::Migration[6.1]
  def up
    rename_column :admin_users, :crypted_password, :encrypted_password
    rename_column :admin_users, :login_count, :sign_in_count
    rename_column :admin_users, :current_login_at, :current_sign_in_at
    rename_column :admin_users, :last_login_at, :last_sign_in_at
    rename_column :admin_users, :current_login_ip, :current_sign_in_ip
    rename_column :admin_users, :last_login_ip, :last_sign_in_ip
    rename_column :admin_users, :failed_login_count, :failed_attempts

    add_column :admin_users, :locked_at, :timestamp
    remove_column :admin_users, :last_request_at
  end

  def down
    rename_column :admin_users, :encrypted_password, :crypted_password
    rename_column :admin_users, :sign_in_count, :login_count
    rename_column :admin_users, :current_sign_in_at, :current_login_at
    rename_column :admin_users, :last_sign_in_at, :last_login_at
    rename_column :admin_users, :current_sign_in_ip, :current_login_ip
    rename_column :admin_users, :last_sign_in_ip, :last_login_ip
    rename_column :admin_users, :failed_attempts, :failed_login_count

    remove_column :admin_users, :locked_at
    add_column :admin_users, :last_request_at, :timestamp
  end
end
