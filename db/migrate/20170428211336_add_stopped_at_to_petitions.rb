class AddStoppedAtToPetitions < ActiveRecord::Migration[4.2]
  def change
    add_column :petitions, :stopped_at, :datetime
  end
end
