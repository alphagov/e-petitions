class AddStartAndEndDateToConstituencies < ActiveRecord::Migration[7.1]
  def change
    add_column :constituencies, :start_date, :date
    add_column :constituencies, :end_date, :date
  end
end
