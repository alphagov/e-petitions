class RenameParliamentResponseAtToGovernmentResponseAt < ActiveRecord::Migration[4.2]
  def change
    rename_column :petitions, :parliament_response_at, :government_response_at
  end
end
