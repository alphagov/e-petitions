class AddIndexesToModerationThresholdReachedAtAndModerationLag < ActiveRecord::Migration[4.2]
  disable_ddl_transaction!

  def up
    add_index :petitions, [:moderation_threshold_reached_at, :moderation_lag], algorithm: :concurrently, name: "index_petitions_on_mt_reached_at_and_moderation_lag"
    add_index :archived_petitions, [:moderation_threshold_reached_at, :moderation_lag], algorithm: :concurrently, name: "index_archived_petitions_on_mt_reached_at_and_moderation_lag"
  end

  def down
    remove_index :petitions, name: "index_petitions_on_mt_reached_at_and_moderation_lag"
    remove_index :archived_petitions, name: "index_archived_petitions_on_mt_reached_at_and_moderation_lag"
  end
end
