class AddRemovalsColumnsToPetitions < ActiveRecord::Migration[6.1]
  def change
    add_column :petitions, :reason_for_removal, :text
    add_column :petitions, :state_at_removal, :string, limit: 10
    add_column :petitions, :removed_at, :datetime
  end
end
