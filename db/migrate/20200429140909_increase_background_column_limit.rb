class IncreaseBackgroundColumnLimit < ActiveRecord::Migration[5.2]
  def up
    change_column :petitions, :background_en, :string, limit: 3000
    change_column :petitions, :background_cy, :string, limit: 3000
  end

  def down
    change_column :petitions, :background_en, :string, limit: 500
    change_column :petitions, :background_cy, :string, limit: 500
  end
end
