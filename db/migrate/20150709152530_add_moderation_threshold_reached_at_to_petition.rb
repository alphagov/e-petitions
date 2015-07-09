class AddModerationThresholdReachedAtToPetition < ActiveRecord::Migration
  def change
    add_column :petitions, :moderation_threshold_reached_at, :datetime
  end
end
