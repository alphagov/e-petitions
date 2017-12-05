class AddModerationLagToPetitions < ActiveRecord::Migration
  def change
    add_column :petitions, :moderation_lag, :integer
    add_column :archived_petitions, :moderation_lag, :integer
  end
end
