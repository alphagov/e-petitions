class ChangeStateDefaultOnArchivedPetitions < ActiveRecord::Migration[4.2]
  def up
    change_column_default :archived_petitions, :state, "closed"
  end

  def down
    change_column_default :archived_petitions, :state, "open"
  end
end
