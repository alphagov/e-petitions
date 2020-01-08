class AddNotNullConstraintToArchivedPetitions < ActiveRecord::Migration[5.2]
  def change
    change_column_null :archived_petitions, :parliament_id, false
  end
end
