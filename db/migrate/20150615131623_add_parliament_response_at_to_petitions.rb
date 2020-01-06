class AddParliamentResponseAtToPetitions < ActiveRecord::Migration[4.2]
  def change
    add_column :petitions, :parliament_response_at, :timestamp
  end
end
