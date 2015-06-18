class AddDebateThresholdReachedAtToPetitions < ActiveRecord::Migration
  def change
    change_table :petitions do |t|
      t.datetime :debate_threshold_reached_at
      t.index :debate_threshold_reached_at
    end
  end
end

