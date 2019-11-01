class AddElectionDateToParliament < ActiveRecord::Migration
  def change
    add_column :parliaments, :election_date, :date
  end
end
