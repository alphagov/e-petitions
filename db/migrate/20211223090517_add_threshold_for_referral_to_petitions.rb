class AddThresholdForReferralToPetitions < ActiveRecord::Migration[6.1]
  def up
    add_column(:petitions, :threshold_for_referral, :integer)

    execute(
      "UPDATE petitions
      SET threshold_for_referral = 50
      WHERE open_at < '2022-01-01';"
    )

    execute(
      "UPDATE petitions
      SET threshold_for_referral = 250
      WHERE open_at IS NULL
      OR open_at >= '2022-01-01';"
    )
  end

  def down
    remove_column(:petitions, :threshold_for_referral)
  end
end
