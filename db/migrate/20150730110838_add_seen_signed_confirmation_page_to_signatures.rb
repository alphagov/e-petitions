class AddSeenSignedConfirmationPageToSignatures < ActiveRecord::Migration
  def change
    add_column :signatures, :seen_signed_confirmation_page, :boolean, null: false, default: false
  end
end
