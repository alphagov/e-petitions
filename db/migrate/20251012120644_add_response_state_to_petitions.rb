class AddResponseStateToPetitions < ActiveRecord::Migration[7.2]
  def change
    add_column :petitions, :response_state, :string, limit: 30, if_not_exists: true
  end
end
