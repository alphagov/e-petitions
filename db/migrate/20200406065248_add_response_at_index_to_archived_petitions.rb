class AddResponseAtIndexToArchivedPetitions < ActiveRecord::Migration[5.2]
  disable_ddl_transaction!

  def up
    unless index_exists?(:archived_petitions, [:government_response_at, :parliament_id], name: "index_archived_petitions_on_response_at_and_parliament_id")
      add_index :archived_petitions, [:government_response_at, :parliament_id], name: "index_archived_petitions_on_response_at_and_parliament_id", algorithm: :concurrently
    end
  end

  def down
    if index_exists?(:archived_petitions, [:government_response_at, :parliament_id], name: "index_archived_petitions_on_response_at_and_parliament_id")
      remove_index :archived_petitions, name: "index_archived_petitions_on_response_at_and_parliament_id"
    end
  end
end
