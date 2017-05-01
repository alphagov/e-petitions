class AddStoppedAtToPetitions < ActiveRecord::Migration
  def change
    add_column :petitions, :stopped_at, :datetime
  end
end
