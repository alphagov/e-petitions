class CreateConstituencies < ActiveRecord::Migration[4.2]
  def change
    create_table :constituencies do |t|
      t.string :name, limit: 100, null: false
      t.string :slug, limit: 100, null: false
      t.string :external_id, limit: 30, null: false
      t.string :ons_code, limit: 10, null: false
      t.string :mp_id, limit: 30
      t.string :mp_name, limit: 100
      t.date   :mp_date
      t.timestamps null: false
    end

    add_index :constituencies, :slug, unique: true
    add_index :constituencies, :external_id, unique: true
  end
end
