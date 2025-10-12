class AddResponseStateToArchivedPetitions < ActiveRecord::Migration[7.2]
  def change
    add_column :archived_petitions, :response_state, :string, limit: 30, if_not_exists: true
  end
end
