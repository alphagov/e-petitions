class CreateHolidays < ActiveRecord::Migration[4.2]
  def change
    create_table :holidays do |t|
      t.date :christmas_start
      t.date :christmas_end
      t.date :easter_start
      t.date :easter_end
      t.timestamps null: false
    end
  end
end
