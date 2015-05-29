class CreateArchivedPetitions < ActiveRecord::Migration
  def change
    create_table :archived_petitions do |t|
      t.string :title, limit: 255, null: false
      t.text :description
      t.text :response
      t.string :state, limit: 10, null: false, default: "open"
      t.text :reason_for_rejection
      t.datetime :opened_at
      t.datetime :closed_at
      t.integer  :signature_count, default: 0
      t.timestamps null: false
    end
  end
end
