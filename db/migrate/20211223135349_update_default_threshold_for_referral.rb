class UpdateDefaultThresholdForReferral < ActiveRecord::Migration[6.1]
  def change
    change_column_default(:sites, :threshold_for_referral, from: 50, to: 250)
  end
end
