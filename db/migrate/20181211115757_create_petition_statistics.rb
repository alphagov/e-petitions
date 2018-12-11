class CreatePetitionStatistics < ActiveRecord::Migration
  def change
    create_table :petition_statistics do |t|
      t.belongs_to :petition, index: { unique: true }, foreign_key: true
      t.timestamp :refreshed_at
      t.integer :duplicate_emails

      t.timestamps
    end
  end
end
