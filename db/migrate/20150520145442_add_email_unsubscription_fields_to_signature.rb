class AddEmailUnsubscriptionFieldsToSignature < ActiveRecord::Migration
  def change
    add_column :signatures, :unsubscribe_token, :string
  end
end
