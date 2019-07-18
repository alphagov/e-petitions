class AddPendingRateToPetitionStatistics < ActiveRecord::Migration
  def change
    add_column :petition_statistics, :pending_rate, :decimal
  end
end
