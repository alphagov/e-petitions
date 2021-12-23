class AddThresholdForDebateToPetitions < ActiveRecord::Migration[6.1]
  def up
    add_column(:petitions, :threshold_for_debate, :integer)

    execute(
      "UPDATE petitions
      SET threshold_for_debate = 5000
      WHERE closed_at < '2020-12-01';"
    )

    execute(
      "UPDATE petitions
      SET threshold_for_debate = 10000
      WHERE closed_at >= '2020-12-01';"
    )
  end

  def down
    remove_column(:petitions, :threshold_for_debate)
  end
end
