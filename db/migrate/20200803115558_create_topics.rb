class CreateTopics < ActiveRecord::Migration[5.2]
  def change
    create_table :topics, id: :serial do |t|
      t.string :code_en, limit: 100, null: false
      t.string :code_cy, limit: 100, null: false
      t.string :name_en, limit: 100, null: false
      t.string :name_cy, limit: 100, null: false
      t.timestamps null: false
    end

    add_index :topics, :code_en, unique: true
    add_index :topics, :code_cy, unique: true
    add_index :topics, :name_en, unique: true
    add_index :topics, :name_cy, unique: true
  end
end
