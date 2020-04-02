class CreateTopics < ActiveRecord::Migration[5.2]
  def change
    create_table :topics, id: :serial do |t|
      t.string :code, limit: 100, null: false
      t.string :name, limit: 100, null: false
      t.timestamps null: false
    end

    add_index :topics, :code, unique: true
    add_index :topics, :name, unique: true
  end
end
