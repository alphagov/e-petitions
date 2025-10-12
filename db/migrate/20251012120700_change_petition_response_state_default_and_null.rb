class ChangePetitionResponseStateDefaultAndNull < ActiveRecord::Migration[7.2]
  def change
    change_column_default :petitions, :response_state, from: nil, to: "pending"
    change_column_null :petitions, :response_state, false
  end
end
