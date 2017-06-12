class AddParliamentGovernmentAndOpeningAt < ActiveRecord::Migration
  def change
    add_column :parliaments, :government, :string, limit: 100
    add_column :parliaments, :opening_at, :datetime
  end
end
