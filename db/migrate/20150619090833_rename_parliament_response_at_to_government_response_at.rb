class RenameParliamentResponseAtToGovernmentResponseAt < ActiveRecord::Migration
  def change
    rename_column :petitions, :parliament_response_at, :government_response_at
  end
end
