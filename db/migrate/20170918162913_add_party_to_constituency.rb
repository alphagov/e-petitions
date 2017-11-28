class AddPartyToConstituency < ActiveRecord::Migration[4.2]
  def change
    add_column :constituencies, :party, :string, limit: 100
  end
end
