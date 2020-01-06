class ChangeSizeOfPetitionBackground < ActiveRecord::Migration[4.2]
  def up
    change_column :petitions, :background, :string, limit: 300
  end

  def down
    change_column :petitions, :background, :string, limit: 200
  end
end
