class DropTrendingPetitions < ActiveRecord::Migration
  def change
    drop_table :trending_petitions do |t|
      t.integer  :petition_id
      t.integer  :signatures_in_last_hour, default: 0
      t.datetime :created_at
      t.datetime :updated_at
    end
  end
end
