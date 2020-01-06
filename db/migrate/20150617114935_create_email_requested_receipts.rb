class CreateEmailRequestedReceipts < ActiveRecord::Migration[4.2]
  def change
    create_table :email_requested_receipts do |t|
      t.references :petition, index: true, foreign_key: true
      t.datetime :government_response
      t.datetime :debate_outcome

      t.timestamps null: false
    end

    reversible do |dir|
      dir.up do
        execute <<-SQL.strip_heredoc
          INSERT INTO email_requested_receipts
          SELECT nextval('email_requested_receipts_id_seq'), petitions.id, petitions.email_requested_at, NULL, current_timestamp, current_timestamp
          FROM petitions
          WHERE petitions.email_requested_at IS NOT NULL
        SQL
      end
      dir.down do
        execute <<-SQL.strip_heredoc
          UPDATE petitions
          SET email_requested_at = email_requested_receipts.government_response
          FROM email_requested_receipts
          WHERE petitions.id = email_requested_receipts.petition_id
        SQL
      end
    end

    remove_column :petitions, :email_requested_at, :datetime
  end
end
