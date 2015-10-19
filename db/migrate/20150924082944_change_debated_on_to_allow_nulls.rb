class ChangeDebatedOnToAllowNulls < ActiveRecord::Migration
  def change
    change_column_null :debate_outcomes, :debated_on, true
  end
end
