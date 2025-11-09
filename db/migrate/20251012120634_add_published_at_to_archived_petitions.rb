class AddPublishedAtToArchivedPetitions < ActiveRecord::Migration[7.2]
  def change
    add_column :archived_petitions, :published_at, :datetime, precision: nil, if_not_exists: true
  end
end
