class AddStateOpeningAtToParliaments < ActiveRecord::Migration[7.2]
  def change
    add_column :parliaments, :state_opening_at, :datetime
  end
end
