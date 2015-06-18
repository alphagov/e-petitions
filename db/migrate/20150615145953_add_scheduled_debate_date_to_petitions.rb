class AddScheduledDebateDateToPetitions < ActiveRecord::Migration
  def change
    add_column :petitions, :scheduled_debate_date, :date
  end
end
