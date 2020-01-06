class AddModerationLagToPetitions < ActiveRecord::Migration[4.2]
  def change
    add_column :petitions, :moderation_lag, :integer
    add_column :archived_petitions, :moderation_lag, :integer
  end
end
