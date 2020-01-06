class AddElectionDateToParliament < ActiveRecord::Migration[4.2]
  def change
    add_column :parliaments, :election_date, :date
  end
end
