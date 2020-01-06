class AddArchivingStartedAtToPetitions < ActiveRecord::Migration[4.2]
  def change
    add_column :petitions, :archiving_started_at, :datetime
  end
end
