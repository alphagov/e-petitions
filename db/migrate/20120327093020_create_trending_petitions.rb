class CreateTrendingPetitions < ActiveRecord::Migration
  def self.up
    create_table :trending_petitions do |t|
      t.integer :petition_id
      t.integer :signatures_in_last_hour, :default => 0

      t.timestamps
    end
  end

  def self.down
    drop_table :trending_petitions
  end
end
