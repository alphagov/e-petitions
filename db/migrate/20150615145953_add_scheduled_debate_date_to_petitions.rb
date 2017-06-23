class AddScheduledDebateDateToPetitions < ActiveRecord::Migration[4.2]
  def change
    add_column :petitions, :scheduled_debate_date, :date
  end
end
