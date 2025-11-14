class AddOccurredOnToArchivedPetitionEmail < ActiveRecord::Migration[8.0]
  def change
    add_column :archived_petition_emails, :occurred_on, :date, if_not_exists: true
  end
end
