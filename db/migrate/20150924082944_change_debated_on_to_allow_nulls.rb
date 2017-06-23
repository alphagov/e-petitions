class ChangeDebatedOnToAllowNulls < ActiveRecord::Migration[4.2]
  def change
    change_column_null :debate_outcomes, :debated_on, true
  end
end
