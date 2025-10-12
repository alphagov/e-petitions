class AddPublishedAtToPetitions < ActiveRecord::Migration[7.2]
  def change
    add_column :petitions, :published_at, :datetime, precision: nil, if_not_exists: true
  end
end
