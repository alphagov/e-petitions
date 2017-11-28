class AddPetitionSummaryToPetition < ActiveRecord::Migration[4.2]
  def change
    add_column :petitions, :response_summary, :string, limit: 500
  end
end
