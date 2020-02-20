class RenameResponseColumns < ActiveRecord::Migration[5.2]
  def change
    rename_column :petitions, :response_threshold_reached_at, :referral_threshold_reached_at
    rename_column :sites, :threshold_for_response, :threshold_for_referral
  end
end
