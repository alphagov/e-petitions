class DropStoppedAtColumnFromPetitions < ActiveRecord::Migration[5.2]
  def change
    remove_column :petitions, :stopped_at, :datetime
  end
end
