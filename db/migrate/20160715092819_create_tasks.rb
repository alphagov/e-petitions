class CreateTasks < ActiveRecord::Migration[4.2]
  def change
    create_table :tasks do |t|
      t.string :name, limit: 60, null: false
      t.timestamps null: false
    end

    add_index :tasks, :name, unique: true
  end
end
