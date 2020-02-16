class CreateDepartments < ActiveRecord::Migration[5.2]
  def change
    create_table :departments, id: :serial do |t|
      t.string :external_id, limit: 30, null: false
      t.string :name, limit: 100, null: false
      t.string :acronym, limit: 10
      t.string :url, limit: 100
      t.date :start_date, null: false
      t.date :end_date
      t.timestamps null: false
    end
  end
end
