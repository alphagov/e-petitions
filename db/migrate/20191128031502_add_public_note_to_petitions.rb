class AddPublicNoteToPetitions < ActiveRecord::Migration[4.2]
  def change
    add_column :petitions, :committee_note, :text
    add_column :archived_petitions, :committee_note, :text
  end
end
