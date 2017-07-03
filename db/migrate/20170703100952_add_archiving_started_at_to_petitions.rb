class AddArchivingStartedAtToPetitions < ActiveRecord::Migration
  def change
    add_column :petitions, :archiving_started_at, :datetime
  end
end
