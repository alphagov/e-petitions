class CreateTrendingPetitionJournals < ActiveRecord::Migration
  def up
    create_table :trending_petition_journals do |t|
      t.references :petition, null: false
      t.date :date, null: false

      t.integer :hour_0_signature_count, default: 0, null: false
      t.integer :hour_1_signature_count, default: 0, null: false
      t.integer :hour_2_signature_count, default: 0, null: false
      t.integer :hour_3_signature_count, default: 0, null: false
      t.integer :hour_4_signature_count, default: 0, null: false
      t.integer :hour_5_signature_count, default: 0, null: false
      t.integer :hour_6_signature_count, default: 0, null: false
      t.integer :hour_7_signature_count, default: 0, null: false
      t.integer :hour_8_signature_count, default: 0, null: false
      t.integer :hour_9_signature_count, default: 0, null: false
      t.integer :hour_10_signature_count, default: 0, null: false
      t.integer :hour_11_signature_count, default: 0, null: false
      t.integer :hour_12_signature_count, default: 0, null: false
      t.integer :hour_13_signature_count, default: 0, null: false
      t.integer :hour_14_signature_count, default: 0, null: false
      t.integer :hour_15_signature_count, default: 0, null: false
      t.integer :hour_16_signature_count, default: 0, null: false
      t.integer :hour_17_signature_count, default: 0, null: false
      t.integer :hour_18_signature_count, default: 0, null: false
      t.integer :hour_19_signature_count, default: 0, null: false
      t.integer :hour_20_signature_count, default: 0, null: false
      t.integer :hour_21_signature_count, default: 0, null: false
      t.integer :hour_22_signature_count, default: 0, null: false
      t.integer :hour_23_signature_count, default: 0, null: false

      t.timestamps null: false
    end

    add_index :trending_petition_journals, :petition_id
    add_index :trending_petition_journals, [:petition_id, :date], unique: true
  end

  def down
    drop_table :trending_petition_journals
  end
end
