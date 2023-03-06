class AddSubscribersToPetitionStatistics < ActiveRecord::Migration[6.1]
  def change
    add_column :petition_statistics, :subscribers, :integer
  end
end
