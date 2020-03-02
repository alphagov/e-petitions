class ChangeDepartmentExternalIdNotNull < ActiveRecord::Migration[5.2]
  def change
    change_column_null :departments, :external_id, true
    change_column_null :departments, :start_date, true
  end
end
