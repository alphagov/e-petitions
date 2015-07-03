class ChangeSizeOfPetitionBackground < ActiveRecord::Migration
  def up
    change_column :petitions, :background, :string, limit: 300
  end

  def down
    change_column :petitions, :background, :string, limit: 200
  end
end
