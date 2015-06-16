class AddPetitionSummaryToPetition < ActiveRecord::Migration
  def change
    add_column :petitions, :response_summary, :string, limit: 500
  end
end
