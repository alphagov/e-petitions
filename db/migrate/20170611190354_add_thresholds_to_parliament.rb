class AddThresholdsToParliament < ActiveRecord::Migration
  def change
    add_column :parliaments, :threshold_for_response, :integer, null: false, default: 10000
    add_column :parliaments, :threshold_for_debate, :integer, null: false, default: 100000
  end
end
