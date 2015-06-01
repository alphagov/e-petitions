class RemoveEncryptedEmailAndPerishableTokenFromSponsors < ActiveRecord::Migration
  def change
    remove_column :sponsors, :encrypted_email, :string, limit: 255
    remove_column :sponsors, :perishable_token, :string, limit: 255
  end
end
