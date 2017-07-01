class DropSeenSignedConfirmationPageFromArchivedSignatures < ActiveRecord::Migration
  def up
    remove_column :archived_signatures, :seen_signed_confirmation_page
  end

  def down
    add_column :archived_signatures, :seen_signed_confirmation_page, :boolean, default: false, null: false
  end
end
