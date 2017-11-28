class ChangeInternalResponseToNotes < ActiveRecord::Migration[4.2]
  def change
    rename_column :petitions, :internal_response, :admin_notes
    remove_column :petitions, :response_required, :boolean, default: false
  end
end
