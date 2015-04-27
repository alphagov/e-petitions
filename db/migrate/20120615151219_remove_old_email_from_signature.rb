class RemoveOldEmailFromSignature < ActiveRecord::Migration
  def self.up
    drop_table :encrypted_signatures if table_exists? :encrypted_signatures

    execute "CREATE TABLE encrypted_signatures LIKE signatures"
    remove_index :encrypted_signatures, :name => "index_signatures_on_email_and_petition_id_and_name"
    remove_column :encrypted_signatures, :email

    unless column_exists? :encrypted_signatures, :encrypted_email
      add_column :encrypted_signatures, :encrypted_email, :string
    end
    add_index :encrypted_signatures, [:encrypted_email, :petition_id, :name], :unique => true, :name => "index_signatures_on_encrypted_email_and_petition_id_and_name"

  end

  def self.down
    drop_table :encrypted_signatures
  end
end
