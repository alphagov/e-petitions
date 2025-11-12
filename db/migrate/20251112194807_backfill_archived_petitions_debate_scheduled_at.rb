class BackfillArchivedPetitionsDebateScheduledAt < ActiveRecord::Migration[7.2]
  disable_ddl_transaction!

  def change
    up_only do
      execute <<~SQL
        UPDATE archived_petitions
        SET debate_scheduled_at = email_requested_for_debate_scheduled_at
        WHERE debate_state IN ('scheduled', 'debated')
      SQL
    end
  end
end
