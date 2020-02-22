class DropLocations < ActiveRecord::Migration[5.2]
  def change
    drop_table :locations, id: :serial do |t|
      t.string :code, limit: 30, null: false
      t.string :name, limit: 100, null: false
      t.date :start_date
      t.date :end_date
      t.datetime :created_at
      t.datetime :updated_at
      t.index [:code], unique: true
      t.index [:name], unique: true
      t.index [:start_date, :end_date]
    end
  end
end
