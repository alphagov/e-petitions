class AddPartyToConstituency < ActiveRecord::Migration
  def change
    add_column :constituencies, :party, :string, limit: 100
  end
end
