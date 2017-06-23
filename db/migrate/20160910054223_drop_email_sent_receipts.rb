class DropEmailSentReceipts < ActiveRecord::Migration[4.2]
  def up
    remove_foreign_key :email_sent_receipts, column: :signature_id
    drop_table :email_sent_receipts
  end

  def down
    create_table :email_sent_receipts do |t|
      t.references :signature, index: true, foreign_key: true
      t.datetime :government_response
      t.datetime :debate_outcome
      t.timestamps null: false
      t.datetime :debate_scheduled
      t.datetime :petition_email
    end
  end
end
