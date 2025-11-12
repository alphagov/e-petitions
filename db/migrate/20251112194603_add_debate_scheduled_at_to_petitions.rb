class AddDebateScheduledAtToPetitions < ActiveRecord::Migration[7.2]
  def change
    add_column :petitions, :debate_scheduled_at, :datetime, precision: nil, if_not_exists: true
  end
end
