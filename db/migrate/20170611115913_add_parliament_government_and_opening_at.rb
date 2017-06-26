class AddParliamentGovernmentAndOpeningAt < ActiveRecord::Migration[4.2]
  def change
    add_column :parliaments, :government, :string, limit: 100
    add_column :parliaments, :opening_at, :datetime
  end
end
