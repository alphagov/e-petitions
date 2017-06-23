class CreateDebateOutcomes < ActiveRecord::Migration[4.2]
  def change
    create_table :debate_outcomes do |t|
      t.references :petition, null: false
      t.date :debated_on, null: false
      t.string :transcript_url, limit: 500
      t.string :video_url, limit: 500
      t.text :overview

      t.timestamps null: false
    end

    add_index :debate_outcomes, [:petition_id], unique: true
    add_index :debate_outcomes, [:petition_id, :debated_on]
  end
end
