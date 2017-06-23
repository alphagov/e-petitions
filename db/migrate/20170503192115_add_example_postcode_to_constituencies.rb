class AddExamplePostcodeToConstituencies < ActiveRecord::Migration[4.2]
  def change
    add_column :constituencies, :example_postcode, :string, limit: 30
  end
end
