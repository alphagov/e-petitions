class AddSignedTokenToSignature < ActiveRecord::Migration[4.2]
  def change
    add_column :signatures, :signed_token, :string
  end
end
