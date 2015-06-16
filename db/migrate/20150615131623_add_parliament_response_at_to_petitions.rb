class AddParliamentResponseAtToPetitions < ActiveRecord::Migration
  def change
    add_column :petitions, :parliament_response_at, :timestamp
  end
end
