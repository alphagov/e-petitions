class AddRemovalsColumnsToArchivedPetitions < ActiveRecord::Migration[6.1]
  def change
    add_column :archived_petitions, :reason_for_removal, :text
    add_column :archived_petitions, :state_at_removal, :string, limit: 10
    add_column :archived_petitions, :removed_at, :datetime
  end
end
