class BackfillPetitionsDebateScheduledAt < ActiveRecord::Migration[7.2]
  disable_ddl_transaction!

  def change
    up_only do
      execute <<~SQL
        UPDATE petitions AS p
        SET debate_scheduled_at = e.debate_scheduled
        FROM email_requested_receipts AS e
        WHERE p.id = e.petition_id
        AND e.debate_scheduled IS NOT NULL
      SQL
    end
  end
end
