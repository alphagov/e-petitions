class CreatePetitionEmails < ActiveRecord::Migration[4.2]
  def change
    create_table :petition_emails do |t|
      t.references :petition
      t.string :subject, null: false
      t.text :body
      t.string :sent_by
      t.timestamps null: false
    end

    add_index :petition_emails, :petition_id
    add_foreign_key :petition_emails, :petitions, on_delete: :cascade
  end
end
