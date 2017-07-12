class CreateTags < ActiveRecord::Migration
  def change
    create_table :tags do |t|
      t.string :name, limit: 50, null: false
      t.string :description, limit: 200
      t.timestamps null: false
    end

    add_index :tags, :name, unique: true
  end
end
