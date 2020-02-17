class IncreasePetitionBackgroundLength < ActiveRecord::Migration[5.2]
  def up
    change_column :petitions, :background, :string, limit: 500
  end

  def down
    change_column :petitions, :background, :string, limit: 300
  end
end
