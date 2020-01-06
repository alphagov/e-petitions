class ChangeNotifyByEmailDefault < ActiveRecord::Migration[4.2]
  def up
    change_column_default :signatures, :notify_by_email, false
  end

  def down
    change_column_default :signatures, :notify_by_email, true
  end
end
