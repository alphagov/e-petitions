class DropConstituencies < ActiveRecord::Migration[5.2]
  def change
    drop_table :constituencies, id: :serial do |t|
      t.string :name, limit: 100, null: false
      t.string :slug, limit: 100, null: false
      t.string :external_id, limit: 30, null: false
      t.string :ons_code, limit: 10, null: false
      t.string :mp_id, limit: 30
      t.string :mp_name, limit: 100
      t.date :mp_date
      t.datetime :created_at, null: false
      t.datetime :updated_at, null: false
      t.string :example_postcode, limit: 30
      t.string :party, limit: 100
      t.index [:external_id], unique: true
      t.index [:slug], unique: true
    end
  end
end
