class ChangeThresholdDefaults < ActiveRecord::Migration[5.2]
  def change
    change_column_default :sites, :minimum_number_of_sponsors, from: 5, to: 2
    change_column_default :sites, :threshold_for_moderation, from: 5, to: 2
    change_column_default :sites, :threshold_for_response, from: 10000, to: 50
    change_column_default :sites, :threshold_for_debate, from: 100000, to: 5000
  end
end
