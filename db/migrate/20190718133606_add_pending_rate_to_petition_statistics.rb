class AddPendingRateToPetitionStatistics < ActiveRecord::Migration[4.2]
  def change
    add_column :petition_statistics, :pending_rate, :decimal
  end
end
