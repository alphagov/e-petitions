class CreatePetitionMailshot < ActiveRecord::Migration[6.1]
  def change
    create_table :archived_petition_mailshots, id: :serial do |t|
      t.belongs_to :petition, index: true, foreign_key: { to_table: :archived_petitions }
      t.string "subject", null: false
      t.text "body"
      t.string "sent_by"
      t.timestamps
    end

    create_table :petition_mailshots, id: :serial do |t|
      t.belongs_to :petition, index: true, foreign_key: { to_table: :petitions }
      t.string "subject", null: false
      t.text "body"
      t.string "sent_by"
      t.timestamps
    end
  end
end
