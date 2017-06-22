class ChangeStateDefaultOnArchivedPetitions < ActiveRecord::Migration
  def up
    change_column_default :archived_petitions, :state, "closed"
  end

  def down
    change_column_default :archived_petitions, :state, "open"
  end
end
