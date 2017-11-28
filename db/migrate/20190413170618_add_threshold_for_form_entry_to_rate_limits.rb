class AddThresholdForFormEntryToRateLimits < ActiveRecord::Migration[4.2]
  def up
    unless column_exists?(:rate_limits, :threshold_for_form_entry)
      add_column :rate_limits, :threshold_for_form_entry, :integer, null: false, default: 0
    end
  end

  def down
    if column_exists?(:rate_limits, :threshold_for_form_entry)
      remove_column :rate_limits, :threshold_for_form_entry
    end
  end
end
