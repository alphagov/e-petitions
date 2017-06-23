class AddThresholdsToParliament < ActiveRecord::Migration[4.2]
  def change
    add_column :parliaments, :threshold_for_response, :integer, null: false, default: 10000
    add_column :parliaments, :threshold_for_debate, :integer, null: false, default: 100000
  end
end
