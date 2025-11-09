class ChangeArchivedPetitionResponseStateDefaultAndNull < ActiveRecord::Migration[7.2]
  def change
    change_column_default :archived_petitions, :response_state, from: nil, to: "pending"
    change_column_null :archived_petitions, :response_state, false
  end
end
