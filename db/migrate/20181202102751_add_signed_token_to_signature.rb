class AddSignedTokenToSignature < ActiveRecord::Migration
  def change
    add_column :signatures, :signed_token, :string
  end
end
