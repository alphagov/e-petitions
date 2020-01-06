class AddSignatureJournalsToArchivedPetitions < ActiveRecord::Migration[4.2]
  def change
    add_column :archived_petitions, :signatures_by_constituency, :jsonb
    add_column :archived_petitions, :signatures_by_country, :jsonb
  end
end
