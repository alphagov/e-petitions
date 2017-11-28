class CreateLocations < ActiveRecord::Migration[4.2]
  def change
    create_table :locations do |t|
      t.string :code, limit: 30, null: false
      t.string :name, limit: 100, null: false
      t.date   :start_date
      t.date   :end_date
      t.timestamps
    end

    add_index :locations, :code, unique: true
    add_index :locations, :name, unique: true
    add_index :locations, [:start_date, :end_date]
  end
end
