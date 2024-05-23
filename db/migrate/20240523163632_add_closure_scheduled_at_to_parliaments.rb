class AddClosureScheduledAtToParliaments < ActiveRecord::Migration[7.1]
  def change
    add_column :parliaments, :closure_scheduled_at, :datetime
  end
end
