class RenameEncryptedEmailColumn < ActiveRecord::Migration
  def change
    rename_column :signatures, :encrypted_email, :email
  end
end
