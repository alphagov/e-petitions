class ChangeNotifyByEmailDefault < ActiveRecord::Migration
  def up
    change_column_default :signatures, :notify_by_email, false
  end

  def down
    change_column_default :signatures, :notify_by_email, true
  end
end
