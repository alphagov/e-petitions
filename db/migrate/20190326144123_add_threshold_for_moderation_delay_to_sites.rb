class AddThresholdForModerationDelayToSites < ActiveRecord::Migration[4.2]
  def change
    add_column :sites, :threshold_for_moderation_delay, :integer, default: 500, null: false
  end
end
