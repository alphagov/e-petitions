class AddModerationThresholdReachedAtToPetition < ActiveRecord::Migration[4.2]
  def change
    add_column :petitions, :moderation_threshold_reached_at, :datetime
  end
end
