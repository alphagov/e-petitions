class ChangeConstituencySlugIndexToUniqueActive < ActiveRecord::Migration[7.1]
  def change
    remove_index :constituencies, :slug, unique: true
    add_index :constituencies, :slug, unique: true, where: "end_date IS NULL"
  end
end
