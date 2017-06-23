class CreateConstituencyPetitionJournals < ActiveRecord::Migration[4.2]
  def change
    create_table :constituency_petition_journals do |t|
      t.string :constituency_id, null: false
      t.references :petition, null: false
      t.integer :signature_count, default: 0, null: false

      t.timestamps null: false
    end

    add_index :constituency_petition_journals, [:petition_id, :constituency_id], unique: true, name: 'idx_constituency_petition_journal_uniqueness'
  end
end
