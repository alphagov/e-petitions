class AddDebateThresholdReachedAtToPetitions < ActiveRecord::Migration[4.2]
  def change
    change_table :petitions do |t|
      t.datetime :debate_threshold_reached_at
      t.index :debate_threshold_reached_at
    end
  end
end

