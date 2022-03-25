class CreateCountries < ActiveRecord::Migration[6.1]
  def change
    create_table :countries, id: { type: :string, limit: 9 } do |t|
      t.string   :name_en, limit: 100, null: false, index: { unique: true }
      t.string   :name_cy, limit: 100, null: false, index: { unique: true }
      t.integer  :population, null: false
      t.geometry :boundary, geographic: true
      t.timestamps
    end
  end
end
