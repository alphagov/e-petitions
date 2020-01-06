class CreateEmailSentReceipts < ActiveRecord::Migration[4.2]
  def change
    create_table :email_sent_receipts do |t|
      t.references :signature, index: true, foreign_key: true
      t.datetime :government_response
      t.datetime :debate_outcome

      t.timestamps null: false
    end

    reversible do |dir|
      dir.up do
        execute <<-SQL.strip_heredoc
          INSERT INTO email_sent_receipts
          SELECT nextval('email_sent_receipts_id_seq'), signatures.id, signatures.last_emailed_at, NULL, current_timestamp, current_timestamp
          FROM signatures
          WHERE signatures.last_emailed_at IS NOT NULL
        SQL
      end
      dir.down do
        execute <<-SQL.strip_heredoc
          UPDATE signatures
          SET last_emailed_at = email_sent_receipts.government_response
          FROM email_sent_receipts
          WHERE signatures.id = email_sent_receipts.signature_id
        SQL
      end
    end

    remove_column :signatures, :last_emailed_at, :datetime
  end
end
