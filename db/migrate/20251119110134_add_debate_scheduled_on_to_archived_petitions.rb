class AddDebateScheduledOnToArchivedPetitions < ActiveRecord::Migration[8.0]
  def change
    add_column :archived_petitions, :debate_scheduled_on, :date, if_not_exists: true
  end
end
