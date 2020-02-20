class AddCompletedAtToPetitions < ActiveRecord::Migration[5.2]
  def change
    add_column :petitions, :completed_at, :datetime
  end
end
