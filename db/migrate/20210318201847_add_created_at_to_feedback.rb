class AddCreatedAtToFeedback < ActiveRecord::Migration[5.2]
  def change
    add_column :feedback, :created_at, :datetime
  end
end
