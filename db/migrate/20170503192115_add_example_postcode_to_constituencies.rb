class AddExamplePostcodeToConstituencies < ActiveRecord::Migration
  def change
    add_column :constituencies, :example_postcode, :string, limit: 30
  end
end
